import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/services/location_service_v2.dart';

/// Network Location Service - Fixed untuk mendapatkan lokasi REAL dari device
/// Menggunakan NETWORK PROVIDER ONLY (WiFi/Cellular triangulation)
/// TIDAK menggunakan IP-based location
class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  
  final LocationServiceV2 _locationServiceV2 = LocationServiceV2();

  // Cache untuk performa - tapi dengan validasi ketat
  Map<String, dynamic>? _cachedLocation;
  DateTime? _cacheTime;
  static const int cacheMaxAgeSeconds = 20; // Optimized: Reduced from 30 to 20

  /// Method utama - HANYA menggunakan Device Network Provider
  /// Tidak ada IP-based fallback karena itu tidak akurat
  Future<Map<String, dynamic>?> getLocationFromNetwork({
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('$_logTag getLocationFromNetwork() called');
        print('$_logTag Force Refresh: $forceRefresh');
        print('═══════════════════════════════════════════════════════════');
      }

      // Clear cache if force refresh
      if (forceRefresh) {
        clearCache();
      }

      // Check cache validity
      if (!forceRefresh && _cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!).inSeconds;
        if (age < cacheMaxAgeSeconds) {
          if (kDebugMode) {
            print('$_logTag ✅ Using cached location (age: ${age}s)');
            print('$_logTag Cache data: ${_cachedLocation!['city']}, ${_cachedLocation!['region']}');
          }
          return _cachedLocation;
        } else {
          if (kDebugMode) {
            print('$_logTag ⚠️ Cache expired (age: ${age}s), fetching fresh data');
          }
          clearCache();
        }
      }

      // Get REAL device location using network provider
      if (kDebugMode) {
        print('$_logTag 📍 Requesting FRESH location from device network provider...');
      }

      final deviceLocation = await _getDeviceNetworkLocation();
      
      if (deviceLocation != null) {
        // Validate location is reasonable (in Indonesia bounds)
        if (_isLocationValid(deviceLocation)) {
          _cachedLocation = deviceLocation;
          _cacheTime = DateTime.now();
          
          if (kDebugMode) {
            print('$_logTag ✅ Network provider location obtained and validated');
            print('$_logTag Location: ${deviceLocation['city']}, ${deviceLocation['region']}');
            print('$_logTag Coordinates: [${deviceLocation['latitude']}, ${deviceLocation['longitude']}]');
            print('$_logTag Accuracy: ${deviceLocation['accuracy']}m');
          }
          
          return deviceLocation;
        } else {
          if (kDebugMode) {
            print('$_logTag ❌ Location validation failed - coordinates outside expected range');
          }
          return null;
        }
      }

      if (kDebugMode) {
        print('$_logTag ❌ Failed to get device network location');
      }
      return null;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('$_logTag ❌ Error getting network location: $e');
        print('$_logTag Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Get ACTUAL device location using Network Provider (WiFi/Cellular)
  /// This is REAL device triangulation, NOT IP-based
  /// OPTIMIZED: Faster timeout with smart retry
  Future<Map<String, dynamic>?> _getDeviceNetworkLocation() async {
    const maxRetries = 2; // Reduced from 3 to 2
    const retryDelay = Duration(seconds: 1); // Reduced from 2 to 1
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('───────────────────────────────────────────────────────────');
          print('$_logTag 📡 Fetching location from DEVICE NETWORK PROVIDER');
          print('$_logTag Attempt: $attempt/$maxRetries');
          print('$_logTag Using: WiFi/Cellular triangulation (NOT GPS, NOT IP)');
          print('───────────────────────────────────────────────────────────');
        }

        // Check connectivity
        final connectivityResult = await Connectivity().checkConnectivity();
        String connectivityType = 'Unknown';
        
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          connectivityType = 'WiFi';
          if (kDebugMode) {
            print('$_logTag 📶 Connected via WiFi - Good for network location');
          }
        } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
          connectivityType = 'Cellular';
          if (kDebugMode) {
            print('$_logTag 📱 Connected via Cellular - Will use cell towers');
          }
        } else {
          if (kDebugMode) {
            print('$_logTag ⚠️ No network connectivity detected');
          }
          throw Exception('No network connectivity available');
        }

        // CRITICAL: Use LocationServiceV2 with useGps: FALSE
        // Smart timeout: WiFi = faster, Cellular = slower
        final timeout = connectivityType == 'WiFi' 
            ? const Duration(seconds: 15)  // WiFi is faster
            : const Duration(seconds: 20); // Cellular needs more time
        
        if (kDebugMode) {
          print('$_logTag 🔄 Calling LocationServiceV2.getCurrentPosition(useGps: false)');
          print('$_logTag ⏱️ Timeout set to ${timeout.inSeconds}s for $connectivityType');
        }

        final Position? position = await _locationServiceV2.getCurrentPosition(
          useGps: false, // CRITICAL: This uses LocationAccuracy.low = Network Provider
        ).timeout(
          timeout,
          onTimeout: () {
            if (kDebugMode) {
              print('$_logTag ⏱️ Timeout after ${timeout.inSeconds}s on attempt $attempt');
            }
            throw TimeoutException('Location request timed out after ${timeout.inSeconds} seconds');
          },
        );

        if (position == null) {
          if (kDebugMode) {
            print('$_logTag ❌ Device returned null position on attempt $attempt');
          }
          
          if (attempt < maxRetries) {
            if (kDebugMode) {
              print('$_logTag 🔄 Retrying in ${retryDelay.inSeconds} second(s)...');
            }
            await Future.delayed(retryDelay);
            continue; // Retry
          }
          
          throw Exception('Device network provider returned null position after $maxRetries attempts');
        }
        
        // Success - return the position processing
        return await _processPosition(position, connectivityType);
        
      } catch (e) {
        if (kDebugMode) {
          print('$_logTag ❌ Attempt $attempt failed: $e');
        }
        
        // If this is the last attempt, rethrow the error
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        // Otherwise, wait and retry
        if (kDebugMode) {
          print('$_logTag 🔄 Retrying in ${retryDelay.inSeconds} second(s)...');
        }
        await Future.delayed(retryDelay);
      }
    }
    
    // Should never reach here due to rethrow, but just in case
    throw Exception('Failed to get location after $maxRetries attempts');
  }
  
  /// Process position data and build result
  Future<Map<String, dynamic>> _processPosition(Position position, String connectivityType) async {
    if (position == null) {
      throw Exception('Position is null');
    }

    if (kDebugMode) {
      print('───────────────────────────────────────────────────────────');
      print('$_logTag ✅ Position received from device!');
      print('$_logTag Latitude: ${position.latitude}');
      print('$_logTag Longitude: ${position.longitude}');
      print('$_logTag Accuracy: ${position.accuracy}m');
      print('$_logTag Timestamp: ${position.timestamp}');
      print('───────────────────────────────────────────────────────────');
    }

    // Validate accuracy - Network provider should give 50-500m accuracy
    if (position.accuracy < 10) {
      if (kDebugMode) {
        print('$_logTag ⚠️ WARNING: Accuracy too good (${position.accuracy}m)');
        print('$_logTag This might be GPS instead of network provider!');
      }
    }

    // Reverse geocode to get address details
    // OPTIMIZED: Reduced timeout for faster response
    String address = 'Unknown Address';
    String city = 'Unknown';
    String region = 'Unknown';
    String country = 'Unknown';
    
    try {
      if (kDebugMode) {
        print('$_logTag 🔍 Reverse geocoding coordinates...');
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 5), // Reduced from 10 to 5 seconds
        onTimeout: () {
          if (kDebugMode) {
            print('$_logTag ⏱️ Geocoding timeout, using coordinates as address');
          }
          return <Placemark>[];
        },
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Build address components
        final street = place.street ?? '';
        final locality = place.locality ?? place.subAdministrativeArea ?? '';
        final administrative = place.administrativeArea ?? '';
        
        city = locality.isNotEmpty ? locality : 'Unknown';
        region = administrative.isNotEmpty ? administrative : 'Unknown';
        country = place.country ?? 'Indonesia';
        
        // Construct full address
        if (street.isNotEmpty && locality.isNotEmpty) {
          address = '$street, $locality';
        } else if (locality.isNotEmpty) {
          address = locality;
        } else {
          address = '$city, $region';
        }

        if (kDebugMode) {
          print('$_logTag ✅ Geocoding successful:');
          print('$_logTag    City: $city');
          print('$_logTag    Region: $region');
          print('$_logTag    Address: $address');
        }
      } else {
        // Use coordinates as fallback
        address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        if (kDebugMode) {
          print('$_logTag ℹ️ No geocoding data, using coordinates');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('$_logTag ⚠️ Reverse geocoding failed: $e');
        print('$_logTag Using coordinates as address fallback');
      }
      address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    // Build result with complete metadata
    final result = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'city': city,
      'region': region,
      'country': country,
      'country_name': country,
      'address': address,
      'connectivity': connectivityType,
      'source': 'Device Network Provider',
      'source_accuracy': _getSourceAccuracyDescription(position.accuracy),
      'provider': connectivityType,
      'type': 'network',
      'timestamp': DateTime.now().toIso8601String(),
      'altitude': position.altitude,
      'speed': position.speed,
      'device_timestamp': position.timestamp?.toIso8601String(),
    };

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('$_logTag ✅ SUCCESSFULLY OBTAINED NETWORK LOCATION');
      print('$_logTag Final Result: $city, $region');
      print('$_logTag Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
      print('$_logTag Source: Device $connectivityType Network Provider');
      print('═══════════════════════════════════════════════════════════');
    }

    return result;
  }

  /// Validate if location coordinates are reasonable
  /// Check if location is within Indonesia bounds
  bool _isLocationValid(Map<String, dynamic> location) {
    try {
      final lat = location['latitude'] as double?;
      final lng = location['longitude'] as double?;
      
      if (lat == null || lng == null) {
        if (kDebugMode) {
          print('$_logTag Validation failed: null coordinates');
        }
        return false;
      }

      // Indonesia bounds (approximate)
      const double indonesiaMinLat = -11.0;  // South
      const double indonesiaMaxLat = 6.0;    // North
      const double indonesiaMinLng = 95.0;   // West
      const double indonesiaMaxLng = 141.0;  // East

      final isValid = lat >= indonesiaMinLat && 
                      lat <= indonesiaMaxLat && 
                      lng >= indonesiaMinLng && 
                      lng <= indonesiaMaxLng;

      if (kDebugMode) {
        print('$_logTag Location validation: [$lat, $lng]');
        print('$_logTag Is in Indonesia bounds: $isValid');
      }

      return isValid;

    } catch (e) {
      if (kDebugMode) {
        print('$_logTag Error validating location: $e');
      }
      return false;
    }
  }

  /// Get source accuracy description based on accuracy value
  String _getSourceAccuracyDescription(double accuracy) {
    if (accuracy < 50) {
      return 'Excellent (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 100) {
      return 'Very Good (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 200) {
      return 'Good (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 500) {
      return 'Fair (±${accuracy.toStringAsFixed(0)}m)';
    } else {
      return 'Poor (±${accuracy.toStringAsFixed(0)}m)';
    }
  }

  /// Clear cached location (for manual refresh)
  void clearCache() {
    _cachedLocation = null;
    _cacheTime = null;
    if (kDebugMode) {
      print('$_logTag 🗑️ Location cache cleared');
    }
  }

  // ============================================================================
  // STATIC HELPER METHODS
  // ============================================================================

  /// Get quality description based on location source
  static String getQualityDescription(String locationType, {String? source}) {
    if (locationType == 'gps') {
      return 'GPS (Very Accurate ±5-10m)';
    }

    if (source?.contains('Device') ?? false) {
      return 'Network Provider (Accurate ±50-500m)';
    }
    
    return 'Network (Accuracy Unknown)';
  }

  /// Get location source info for display
  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';

    final source = location['source'] as String? ?? 'Unknown';
    final connectivity = location['connectivity'] as String? ?? '';

    return '$connectivity Network Provider\n$source';
  }

  /// Check if location is from device network provider
  static bool isDeviceNetworkLocation(Map<String, dynamic>? location) {
    final source = location?['source'] as String?;
    return source?.contains('Device') ?? false;
  }

  /// Get accuracy in meters
  static double? getAccuracy(Map<String, dynamic>? location) {
    return location?['accuracy'] as double?;
  }

  /// Get source accuracy description
  static String getSourceAccuracyDescription(Map<String, dynamic>? location) {
    return location?['source_accuracy'] as String? ?? 'Unknown';
  }

  /// Format accuracy description for UI
  static String getAccuracyDescription(double accuracy) {
    if (accuracy < 50) {
      return 'Sangat Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 150) {
      return 'Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 300) {
      return 'Cukup Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 500) {
      return 'Kurang Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else {
      return 'Sangat Kurang Akurat (±${accuracy.toStringAsFixed(0)}m)';
    }
  }

  /// Get accuracy level for UI color coding
  static String getAccuracyLevel(double accuracy) {
    if (accuracy < 50) return 'excellent';
    if (accuracy < 150) return 'good';
    if (accuracy < 300) return 'fair';
    if (accuracy < 500) return 'poor';
    return 'very_poor';
  }
}