import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/services/location_service_v2.dart';

/// Network Location Service - OPTIMIZED VERSION
/// ✅ Faster timeout (5-8 seconds instead of 15-20)
/// ✅ Smart fallback to last known position
/// ✅ Better cache management
/// ✅ Progressive loading
class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  
  final LocationServiceV2 _locationServiceV2 = LocationServiceV2();

  // Cache dengan TTL lebih pendek untuk data fresh
  Map<String, dynamic>? _cachedLocation;
  DateTime? _cacheTime;
  static const int cacheMaxAgeSeconds = 15; // Reduced from 20 to 15

  // Last known position sebagai fallback
  Position? _lastKnownPosition;
  DateTime? _lastKnownTime;

  /// MAIN METHOD - OPTIMIZED dengan Smart Fallback
  Future<Map<String, dynamic>?> getLocationFromNetwork({
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('$_logTag 🚀 OPTIMIZED getLocationFromNetwork()');
        print('$_logTag Force Refresh: $forceRefresh');
        print('═══════════════════════════════════════════════════════════');
      }

      // ✅ Step 1: Check valid cache first (fastest)
      if (!forceRefresh && _cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!).inSeconds;
        if (age < cacheMaxAgeSeconds) {
          if (kDebugMode) {
            print('$_logTag ⚡ Using CACHE (age: ${age}s) - INSTANT RESPONSE');
          }
          return _cachedLocation;
        }
      }

      // ✅ Step 2: Try to get fresh location with FAST timeout
      try {
        final deviceLocation = await _getDeviceNetworkLocationOptimized();
        
        if (deviceLocation != null && _isLocationValid(deviceLocation)) {
          _cachedLocation = deviceLocation;
          _cacheTime = DateTime.now();
          
          // Store as last known position
          _lastKnownPosition = Position(
            latitude: deviceLocation['latitude'],
            longitude: deviceLocation['longitude'],
            timestamp: DateTime.now(),
            accuracy: deviceLocation['accuracy'] ?? 100.0,
            altitude: deviceLocation['altitude'] ?? 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: deviceLocation['speed'] ?? 0.0,
            speedAccuracy: 0.0,
          );
          _lastKnownTime = DateTime.now();
          
          if (kDebugMode) {
            print('$_logTag ✅ Fresh location obtained successfully');
          }
          return deviceLocation;
        }
      } catch (e) {
        if (kDebugMode) {
          print('$_logTag ⚠️ Fresh location failed: $e');
        }
      }

      // ✅ Step 3: Fallback to Last Known Position (if available)
      if (_lastKnownPosition != null && _lastKnownTime != null) {
        final age = DateTime.now().difference(_lastKnownTime!).inMinutes;
        if (age < 10) { // Use if less than 10 minutes old
          if (kDebugMode) {
            print('$_logTag 🔄 Using LAST KNOWN position (${age}m old)');
          }
          return await _processPosition(_lastKnownPosition!, 'Cached', isLastKnown: true);
        }
      }

      // ✅ Step 4: Try to get Android/iOS last known position
      try {
        final systemLastKnown = await _locationServiceV2.getLastKnownPosition();
        if (systemLastKnown != null) {
          if (kDebugMode) {
            print('$_logTag 📍 Using SYSTEM last known position');
          }
          return await _processPosition(systemLastKnown, 'System Cache', isLastKnown: true);
        }
      } catch (e) {
        if (kDebugMode) {
          print('$_logTag ⚠️ System last known failed: $e');
        }
      }

      if (kDebugMode) {
        print('$_logTag ❌ All methods failed to get location');
      }
      return null;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('$_logTag ❌ Critical error: $e');
        print('$_logTag Stack: $stackTrace');
      }
      
      // Last resort: return last known if available
      if (_lastKnownPosition != null) {
        if (kDebugMode) {
          print('$_logTag 🆘 Emergency fallback to last known position');
        }
        return await _processPosition(_lastKnownPosition!, 'Emergency Cache', isLastKnown: true);
      }
      
      return null;
    }
  }

  /// OPTIMIZED: Faster device network location with smart retry
  Future<Map<String, dynamic>?> _getDeviceNetworkLocationOptimized() async {
    // ✅ OPTIMIZED: Only 1 retry with faster timeout
    const maxRetries = 1; // Reduced from 2
    const retryDelay = Duration(milliseconds: 500); // Reduced from 1 second
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('─────────────────────────────────────────────────────────');
          print('$_logTag 🔍 Attempt $attempt/$maxRetries (OPTIMIZED)');
          print('─────────────────────────────────────────────────────────');
        }

        // Check connectivity
        final connectivityResult = await Connectivity().checkConnectivity();
        String connectivityType = 'Unknown';
        
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          connectivityType = 'WiFi';
        } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
          connectivityType = 'Cellular';
        } else {
          if (kDebugMode) {
            print('$_logTag ⚠️ No network connectivity');
          }
          throw Exception('No network connectivity available');
        }

        // ✅ OPTIMIZED: Much faster timeout
        // WiFi: 5 seconds (reduced from 15)
        // Cellular: 8 seconds (reduced from 20)
        final timeout = connectivityType == 'WiFi' 
            ? const Duration(seconds: 5)  // WiFi is fast
            : const Duration(seconds: 8); // Cellular needs more time
        
        if (kDebugMode) {
          print('$_logTag ⏱️ Timeout: ${timeout.inSeconds}s for $connectivityType');
          print('$_logTag 🔄 Fetching location...');
        }

        final Position? position = await _locationServiceV2.getCurrentPosition(
          useGps: false, // Network provider only
        ).timeout(
          timeout,
          onTimeout: () {
            if (kDebugMode) {
              print('$_logTag ⏱️ Timeout after ${timeout.inSeconds}s');
            }
            throw TimeoutException('Location timeout after ${timeout.inSeconds}s');
          },
        );

        if (position == null) {
          if (kDebugMode) {
            print('$_logTag ❌ Position is null');
          }
          
          if (attempt < maxRetries) {
            if (kDebugMode) {
              print('$_logTag 🔄 Retrying in ${retryDelay.inMilliseconds}ms...');
            }
            await Future.delayed(retryDelay);
            continue;
          }
          
          throw Exception('Position is null after $maxRetries attempts');
        }
        
        // Success - process and return
        return await _processPosition(position, connectivityType);
        
      } catch (e) {
        if (kDebugMode) {
          print('$_logTag ❌ Attempt $attempt failed: $e');
        }
        
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        if (kDebugMode) {
          print('$_logTag 🔄 Retrying...');
        }
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Failed after $maxRetries attempts');
  }
  
  /// Process position with OPTIMIZED geocoding
  Future<Map<String, dynamic>> _processPosition(
    Position position, 
    String connectivityType,
    {bool isLastKnown = false}
  ) async {
    if (kDebugMode) {
      print('─────────────────────────────────────────────────────────');
      print('$_logTag ✅ Position received!');
      print('$_logTag Lat: ${position.latitude}');
      print('$_logTag Lng: ${position.longitude}');
      print('$_logTag Accuracy: ${position.accuracy}m');
      print('$_logTag Source: ${isLastKnown ? 'CACHED' : 'FRESH'}');
      print('─────────────────────────────────────────────────────────');
    }

    // Reverse geocode with FAST timeout
    String address = 'Unknown Address';
    String city = 'Unknown';
    String region = 'Unknown';
    String country = 'Indonesia';
    
    try {
      if (kDebugMode) {
        print('$_logTag 🔍 Geocoding...');
      }

      // ✅ OPTIMIZED: Faster geocoding timeout (3s instead of 5s)
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 3), // Reduced from 5 to 3
        onTimeout: () {
          if (kDebugMode) {
            print('$_logTag ⏱️ Geocoding timeout - using coordinates');
          }
          return <Placemark>[];
        },
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        final street = place.street ?? '';
        final locality = place.locality ?? place.subAdministrativeArea ?? '';
        final administrative = place.administrativeArea ?? '';
        
        city = locality.isNotEmpty ? locality : 'Unknown';
        region = administrative.isNotEmpty ? administrative : 'Unknown';
        country = place.country ?? 'Indonesia';
        
        if (street.isNotEmpty && locality.isNotEmpty) {
          address = '$street, $locality';
        } else if (locality.isNotEmpty) {
          address = locality;
        } else {
          address = '$city, $region';
        }

        if (kDebugMode) {
          print('$_logTag ✅ Geocoded: $city, $region');
        }
      } else {
        address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('$_logTag ⚠️ Geocoding failed: $e');
      }
      address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    // Build result
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
      'source': isLastKnown ? 'Cached Location' : 'Device Network Provider',
      'source_accuracy': _getSourceAccuracyDescription(position.accuracy),
      'provider': connectivityType,
      'type': 'network',
      'timestamp': DateTime.now().toIso8601String(),
      'altitude': position.altitude,
      'speed': position.speed,
      'device_timestamp': position.timestamp?.toIso8601String(),
      'is_cached': isLastKnown,
    };

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('$_logTag ✅ SUCCESS: $city, $region');
      print('$_logTag Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
      print('$_logTag Source: ${result['source']}');
      print('═══════════════════════════════════════════════════════════');
    }

    return result;
  }

  /// Validate location
  bool _isLocationValid(Map<String, dynamic> location) {
    try {
      final lat = location['latitude'] as double?;
      final lng = location['longitude'] as double?;
      
      if (lat == null || lng == null) return false;

      // Indonesia bounds
      const double indonesiaMinLat = -11.0;
      const double indonesiaMaxLat = 6.0;
      const double indonesiaMinLng = 95.0;
      const double indonesiaMaxLng = 141.0;

      return lat >= indonesiaMinLat && 
             lat <= indonesiaMaxLat && 
             lng >= indonesiaMinLng && 
             lng <= indonesiaMaxLng;

    } catch (e) {
      return false;
    }
  }

  /// Get source accuracy description
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

  /// Clear cache
  void clearCache() {
    _cachedLocation = null;
    _cacheTime = null;
    // Don't clear last known position - keep as emergency fallback
    if (kDebugMode) {
      print('$_logTag 🗑️ Cache cleared (last known position preserved)');
    }
  }

  // ============================================================================
  // STATIC HELPER METHODS (unchanged)
  // ============================================================================

  static String getQualityDescription(String locationType, {String? source}) {
    if (locationType == 'gps') {
      return 'GPS (Very Accurate ±5-10m)';
    }
    if (source?.contains('Device') ?? false) {
      return 'Network Provider (Accurate ±50-500m)';
    }
    return 'Network (Accuracy Unknown)';
  }

  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';
    final source = location['source'] as String? ?? 'Unknown';
    final connectivity = location['connectivity'] as String? ?? '';
    return '$connectivity Network Provider\n$source';
  }

  static bool isDeviceNetworkLocation(Map<String, dynamic>? location) {
    final source = location?['source'] as String?;
    return source?.contains('Device') ?? false;
  }

  static double? getAccuracy(Map<String, dynamic>? location) {
    return location?['accuracy'] as double?;
  }

  static String getSourceAccuracyDescription(Map<String, dynamic>? location) {
    return location?['source_accuracy'] as String? ?? 'Unknown';
  }

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

  static String getAccuracyLevel(double accuracy) {
    if (accuracy < 50) return 'excellent';
    if (accuracy < 150) return 'good';
    if (accuracy < 300) return 'fair';
    if (accuracy < 500) return 'poor';
    return 'very_poor';
  }
}