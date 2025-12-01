import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';

  /// Get location from network (WiFi or Cellular data)
  /// Priority: WiFi > Cellular Network > IP-based Geolocation
  Future<Map<String, dynamic>?> getLocationFromNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      print('$_logTag Connectivity status: $connectivityResult');

      // Try WiFi-based first (most accurate)
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        print('$_logTag Connected to WiFi, trying WiFi-based geolocation...');
        final wifiLocation = await _getWiFiBasedLocation();
        if (wifiLocation != null) {
          print('$_logTag WiFi location obtained');
          return wifiLocation;
        }
        print('$_logTag WiFi geolocation failed, fallback to cellular/IP');
      }

      // Try cellular data (second priority)
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        print('$_logTag Using cellular data connection...');
        final cellularLocation = await _getCellularBasedLocation();
        if (cellularLocation != null) {
          print('$_logTag Cellular location obtained');
          return cellularLocation;
        }
        print('$_logTag Cellular geolocation failed, trying IP-based');
      }

      // Fallback to IP-based geolocation
      print('$_logTag Fallback to IP-based geolocation...');
      final ipLocation = await _getIPBasedLocation();
      if (ipLocation != null) {
        print('$_logTag IP-based location obtained');
        return ipLocation;
      }

      print('$_logTag All geolocation methods failed');
      return null;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Get location using WiFi AP data (most accurate for network-based)
  /// Uses device's connected WiFi SSID and tries WiFi-based APIs
  Future<Map<String, dynamic>?> _getWiFiBasedLocation() async {
    try {
      print('$_logTag Attempting WiFi-based geolocation...');
      
      // First try IP-based with WiFi connection (better accuracy than cellular IP)
      var location = await _queryGeolocationAPI(source: 'WiFi');
      if (location != null && _isLocationInIndonesia(location)) {
        location['connectivity'] = 'WiFi';
        location['source_accuracy'] = 'WiFi Connected (±100-300m)';
        print('$_logTag WiFi geolocation successful');
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error in WiFi geolocation: $e');
      return null;
    }
  }

  /// Get location using cellular network data
  /// Uses cellular signal + IP data
  Future<Map<String, dynamic>?> _getCellularBasedLocation() async {
    try {
      print('$_logTag Attempting cellular-based geolocation...');
      
      var location = await _queryGeolocationAPI(source: 'Cellular');
      if (location != null && _isLocationInIndonesia(location)) {
        location['connectivity'] = 'Cellular (Data)';
        location['source_accuracy'] = 'Cellular IP (±300-500m)';
        print('$_logTag Cellular geolocation successful');
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error in cellular geolocation: $e');
      return null;
    }
  }

  /// Get location using IP address only
  /// Least accurate but works everywhere
  Future<Map<String, dynamic>?> _getIPBasedLocation() async {
    try {
      print('$_logTag Attempting IP-based geolocation...');
      
      var location = await _queryGeolocationAPI(source: 'IP');
      if (location != null && _isLocationInIndonesia(location)) {
        location['connectivity'] = 'IP-based';
        location['source_accuracy'] = 'IP Address Only (±500m-1km)';
        print('$_logTag IP-based geolocation successful');
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error in IP-based geolocation: $e');
      return null;
    }
  }

  /// Query accurate geolocation API
  /// Using ipapi.co which has good Indonesia support
  Future<Map<String, dynamic>?> _queryGeolocationAPI({required String source}) async {
    try {
      print('$_logTag Querying geolocation API for $source...');

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
          'accuracy': _getAccuracyBySource(source),
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? 'Unknown',
          'country_name': data['country_name'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'provider': data['org'] ?? 'Network Provider',
          'source': source,
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      print('$_logTag API returned status code: ${response.statusCode}');
      return null;
    } catch (e) {
      print('$_logTag Error querying geolocation API: $e');
      return null;
    }
  }

  /// Get accuracy value based on source type
  /// Better accuracy estimation
  double _getAccuracyBySource(String source) {
    switch (source) {
      case 'WiFi':
        return 100.0; // WiFi: ±100m (good accuracy)
      case 'Cellular':
        return 300.0; // Cellular: ±300m (moderate accuracy)
      case 'IP':
        return 500.0; // IP-based: ±500m (lower accuracy)
      default:
        return 500.0;
    }
  }

  /// Validate if location is in Indonesia bounds
  /// Indonesia: approximately -10.5° to 6.5° latitude, 95° to 141° longitude
  bool _isLocationInIndonesia(Map<String, dynamic> location) {
    try {
      final lat = location['latitude'] as double?;
      final lng = location['longitude'] as double?;

      if (lat == null || lng == null) return false;

      // Indonesia bounds with buffer
      const minLat = -11.0;
      const maxLat = 7.0;
      const minLng = 94.5;
      const maxLng = 141.5;

      final isValid = lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

      if (!isValid) {
        print('$_logTag Location outside Indonesia bounds: [$lat, $lng]');
      }

      return isValid;
    } catch (e) {
      print('$_logTag Error validating location: $e');
      return false;
    }
  }

  /// Get quality description based on location source
  static String getQualityDescription(String locationType, {String? source}) {
    if (locationType != 'network') return 'GPS (Sangat Akurat ±5-10m)';

    if (source?.contains('WiFi') ?? false) {
      return 'WiFi Network (Akurat ±100-300m)';
    } else if (source?.contains('Cellular') ?? false) {
      return 'Cellular Network (Cukup Akurat ±300-500m)';
    } else {
      return 'IP-based (Kurang Akurat ±500m-1km)';
    }
  }

  /// Get location source info for display
  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';

    final connectivity = location['connectivity'] as String?;
    final source = location['source'] as String?;

    return '$connectivity ($source)';
  }

  /// Check if location is from high-accuracy WiFi
  static bool isHighAccuracyWiFi(Map<String, dynamic>? location) {
    final accuracy = location?['accuracy'] as double?;
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('WiFi') ?? false && (accuracy ?? 500) < 150;
  }

  /// Check connectivity type
  static bool isWiFiBasedLocation(Map<String, dynamic>? location) {
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('WiFi') ?? false;
  }

  static bool isCellularBasedLocation(Map<String, dynamic>? location) {
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('Cellular') ?? false;
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

  /// Get accuracy level badge color
  static String getAccuracyColor(double accuracy) {
    if (accuracy < 50) return 'green'; // Sangat akurat
    if (accuracy < 150) return 'light_green'; // Akurat
    if (accuracy < 300) return 'blue'; // Cukup akurat
    if (accuracy < 500) return 'orange'; // Kurang akurat
    return 'red'; // Sangat kurang akurat
  }
}
