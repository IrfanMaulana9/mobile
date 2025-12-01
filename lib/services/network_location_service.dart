import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import '../data/services/location_service_v2.dart';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  
  final LocationServiceV2 _locationServiceV2 = LocationServiceV2();

  /// Add current position cache untuk performa
  Map<String, dynamic>? _cachedLocation;
  DateTime? _cacheTime;
  static const int cacheMaxAgeSeconds = 60; // 1 menit cache

  /// Improved method to use device's actual network provider location
  /// Now uses Geolocator with LocationAccuracy.low (network provider)
  /// Falls back to IP-based only if network provider fails
  Future<Map<String, dynamic>?> getLocationFromNetwork({
    bool forceRefresh = true,
  }) async {
    try {
      // Check cache dulu jika tidak force refresh
      if (!forceRefresh && _cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!).inSeconds;
        if (age < cacheMaxAgeSeconds) {
          print('$_logTag Using cached location (age: ${age}s)');
          return _cachedLocation;
        }
      }

      // This gives actual device location via WiFi/Cellular triangulation
      print('$_logTag Attempting to get NETWORK PROVIDER location from device...');
      final deviceLocation = await _getDeviceNetworkLocation();
      
      if (deviceLocation != null) {
        _cachedLocation = deviceLocation;
        _cacheTime = DateTime.now();
        print('$_logTag ✅ Network provider location obtained from device');
        return deviceLocation;
      }

      print('$_logTag ⚠️ Device network location failed, falling back to IP-based...');
      final ipLocation = await _getIPBasedLocation();
      if (ipLocation != null) {
        _cachedLocation = ipLocation;
        _cacheTime = DateTime.now();
        print('$_logTag IP-based location obtained as fallback');
        return ipLocation;
      }

      print('$_logTag ❌ All geolocation methods failed');
      return null;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Get actual device location using network provider
  /// Uses LocationAccuracy.low which uses WiFi/Cellular triangulation
  /// This is the REAL location, not IP-based guess
  Future<Map<String, dynamic>?> _getDeviceNetworkLocation() async {
    try {
      print('$_logTag Requesting location from device network provider...');
      
      // Use the correct Position type from geolocator package
      final Position? devicePosition = await _locationServiceV2.getCurrentPosition(
        useGps: false, // <-- This makes it use LocationAccuracy.low (network provider)
      );

      // Handle null position
      if (devicePosition == null) {
        print('$_logTag ❌ Device returned null position');
        return null;
      }

      print('$_logTag ✅ Device position obtained: [${devicePosition.latitude}, ${devicePosition.longitude}]');
      print('$_logTag Accuracy from device: ${devicePosition.accuracy}m');

      // Try to reverse geocode for address
      String? address;
      String city = 'Unknown';
      String region = 'Unknown';
      
      try {
        final placemarks = await placemarkFromCoordinates(
          devicePosition.latitude,
          devicePosition.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.street}, ${place.locality}';
          city = place.locality ?? 'Unknown';
          region = place.administrativeArea ?? 'Unknown';
          print('$_logTag Address from device: $address');
        }
      } catch (e) {
        print('$_logTag Warning: Could not reverse geocode: $e');
      }

      // Determine connectivity type
      final connectivityResult = await Connectivity().checkConnectivity();
      String connectivityType = 'Unknown';
      
      if (connectivityResult == ConnectivityResult.wifi) {
        connectivityType = 'WiFi';
      } else if (connectivityResult == ConnectivityResult.mobile) {
        connectivityType = 'Cellular';
      }

      return {
        'latitude': devicePosition.latitude,
        'longitude': devicePosition.longitude,
        'accuracy': devicePosition.accuracy,
        'city': city,
        'region': region,
        'country': 'ID',
        'country_name': 'Indonesia',
        'address': address ?? '$city, $region',
        'connectivity': '$connectivityType Network Provider',
        'source': 'Device Network Provider',
        'source_accuracy': 'Network Provider (±100-300m)',
        'provider': connectivityType,
        'type': 'network',
        'timestamp': DateTime.now().toIso8601String(),
        'altitude': devicePosition.altitude,
        'speed': devicePosition.speed,
      };
    } catch (e) {
      print('$_logTag Error getting device network location: $e');
      return null;
    }
  }

  /// Get location using IP address (fallback only)
  Future<Map<String, dynamic>?> _getIPBasedLocation() async {
    try {
      print('$_logTag Querying IP-based geolocation API...');

      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        print('$_logTag API Response - City: ${data['city']}, Region: ${data['region']}, Country: ${data['country_code']}');

        final latitude = double.tryParse(data['latitude'].toString());
        final longitude = double.tryParse(data['longitude'].toString());

        if (latitude == null || longitude == null) {
          print('$_logTag Invalid coordinates received');
          return null;
        }

        return {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': 500.0, // IP-based is very inaccurate
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? 'ID',
          'country_name': data['country_name'] ?? 'Indonesia',
          'isp': data['org'] ?? 'Unknown',
          'provider': data['org'] ?? 'ISP Provider',
          'source': 'IP Address (Fallback)',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
          'source_accuracy': 'IP Address Only (±500m-1km) - NOT ACCURATE',
          'connectivity': 'IP-based Only',
        };
      }

      print('$_logTag IP API returned status code: ${response.statusCode}');
      return null;
    } catch (e) {
      print('$_logTag Error querying IP geolocation API: $e');
      return null;
    }
  }

  /// Get quality description based on location source
  static String getQualityDescription(String locationType, {String? source}) {
    if (locationType != 'network') return 'GPS (Sangat Akurat ±5-10m)';

    if (source?.contains('Device') ?? false) {
      return 'Network Provider Device (Akurat ±100-300m)'; // Real device location
    } else if (source?.contains('WiFi') ?? false) {
      return 'WiFi Network (Akurat ±80-150m)';
    } else if (source?.contains('Cellular') ?? false) {
      return 'Cellular Network (Cukup Akurat ±200-500m)';
    } else if (source?.contains('IP') ?? false) {
      return 'IP-based (Kurang Akurat ±500m-1km)'; // Fallback only
    } else {
      return 'Network (Akurasi Tidak Diketahui)';
    }
  }

  /// Get location source info for display
  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';

    final source = location['source'] as String? ?? 'Unknown';
    final connectivity = location['connectivity'] as String? ?? '';

    return '$connectivity\n$source';
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
    if (accuracy < 50) return 'excellent'; // Green
    if (accuracy < 150) return 'good'; // Light Green
    if (accuracy < 300) return 'fair'; // Blue
    if (accuracy < 500) return 'poor'; // Orange
    return 'very_poor'; // Red
  }

  /// Clear cached location (untuk refresh manual)
  void clearCache() {
    _cachedLocation = null;
    _cacheTime = null;
    print('$_logTag Location cache cleared');
  }
}
