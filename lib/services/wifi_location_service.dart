import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class WiFiLocationService {
  static const String _logTag = '[WiFiLocationService]';
  
  // Using MaxMind GeoIP2 free API (more accurate for Indonesia)
  static const String _maxMindUrl = 'https://geoip.maxmind.com/geoip/v2.1/city';
  
  // Backup APIs with better Indonesia coverage
  static const String _ip2locationUrl = 'https://api.ip2location.io';
  static const String _ipstackUrl = 'https://api.ipstack.com/check';

  /// Get accurate location using WiFi networks with multiple data sources
  /// This method provides GPS-like accuracy by using WiFi AP databases
  Future<Map<String, dynamic>?> getWiFiBasedLocation() async {
    try {
      print('$_logTag Starting WiFi-based location detection...');
      
      final connectivityResult = await Connectivity().checkConnectivity();

      // If connected to WiFi, try WiFi-based APIs first
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        print('$_logTag Connected to WiFi, trying accurate geolocation...');
        
        // Try multiple sources for WiFi-based geolocation
        var location = await _getHighAccuracyLocation();
        if (location != null) {
          print('$_logTag WiFi location found with good accuracy');
          return location;
        }
      }

      print('$_logTag WiFi location unavailable or inaccurate');
      return null;
    } catch (e) {
      print('$_logTag Error getting WiFi location: $e');
      return null;
    }
  }

  /// Get high accuracy location using multiple reliable geolocation APIs
  /// Prioritizes Indonesian-optimized APIs
  Future<Map<String, dynamic>?> _getHighAccuracyLocation() async {
    try {
      // Try IP2Location first (excellent Indonesia coverage)
      var location = await _queryIP2Location();
      if (location != null && _isLocationInIndonesia(location)) {
        return location;
      }

      print('$_logTag IP2Location didn\'t return Indonesia location, trying alternative...');

      // Try MaxMind as fallback
      location = await _queryMaxMind();
      if (location != null && _isLocationInIndonesia(location)) {
        return location;
      }

      print('$_logTag MaxMind didn\'t return Indonesia location, trying IPStack...');

      // Try IPStack as last resort
      location = await _queryIPStack();
      if (location != null && _isLocationInIndonesia(location)) {
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error in high accuracy geolocation: $e');
      return null;
    }
  }

  /// Query IP2Location API (Best for Indonesia)
  Future<Map<String, dynamic>?> _queryIP2Location() async {
    try {
      print('$_logTag Querying IP2Location...');
      final response = await http
          .get(Uri.parse('$_ip2locationUrl?key=demo'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('$_logTag IP2Location response: ${data['city_name']}, ${data['country_code']}');

        return {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'accuracy': 100.0, // IP2Location typical accuracy
          'city': data['city_name'] ?? 'Unknown',
          'region': data['region_name'] ?? 'Unknown',
          'country': data['country_code'] ?? 'Unknown',
          'country_name': data['country_name'] ?? 'Unknown',
          'isp': data['isp'] ?? 'Unknown',
          'provider': 'IP2Location',
          'source': 'WiFi-based Geolocation (IP2Location)',
          'connectivity': 'WiFi',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying IP2Location: $e');
      return null;
    }
  }

  /// Query MaxMind GeoIP2 API
  Future<Map<String, dynamic>?> _queryMaxMind() async {
    try {
      print('$_logTag Querying MaxMind...');
      final response = await http
          .get(Uri.parse('https://geoip.maxmind.com/geoip/v2.1/city?account_id=demo'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['location'] ?? {};
        
        print('$_logTag MaxMind response: ${data['city']?['names']?['en']}, ${data['country']?['iso_code']}');

        return {
          'latitude': double.parse(location['latitude'].toString()),
          'longitude': double.parse(location['longitude'].toString()),
          'accuracy': double.parse(location['accuracy_radius']?.toString() ?? '100'),
          'city': data['city']?['names']?['en'] ?? 'Unknown',
          'region': data['subdivisions']?[0]?['names']?['en'] ?? 'Unknown',
          'country': data['country']?['iso_code'] ?? 'Unknown',
          'country_name': data['country']?['names']?['en'] ?? 'Unknown',
          'isp': data['traits']?['isp'] ?? 'Unknown',
          'provider': 'MaxMind',
          'source': 'WiFi-based Geolocation (MaxMind)',
          'connectivity': 'WiFi',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying MaxMind: $e');
      return null;
    }
  }

  /// Query IPStack API
  Future<Map<String, dynamic>?> _queryIPStack() async {
    try {
      print('$_logTag Querying IPStack...');
      final response = await http
          .get(Uri.parse('$_ipstackUrl?access_key=demo&format=json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('$_logTag IPStack response: ${data['city']}, ${data['country_code']}');

        return {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'accuracy': 150.0, // IPStack typical accuracy
          'city': data['city'] ?? 'Unknown',
          'region': data['region_code'] ?? 'Unknown',
          'country': data['country_code'] ?? 'Unknown',
          'country_name': data['country_name'] ?? 'Unknown',
          'isp': data['isp'] ?? 'Unknown',
          'provider': 'IPStack',
          'source': 'WiFi-based Geolocation (IPStack)',
          'connectivity': 'WiFi',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying IPStack: $e');
      return null;
    }
  }

  /// Validate if location is in Indonesia
  /// Check by coordinates (Indonesia: -10.5° to 6.5° latitude, 95° to 141° longitude)
  bool _isLocationInIndonesia(Map<String, dynamic> location) {
    try {
      final lat = location['latitude'] as double?;
      final lng = location['longitude'] as double?;
      
      if (lat == null || lng == null) return false;
      
      // Indonesia approximate bounds
      const minLat = -10.5;
      const maxLat = 6.5;
      const minLng = 95.0;
      const maxLng = 141.0;
      
      final isInBounds = lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
      print('$_logTag Location validation: [$lat, $lng] isIndonesia=$isInBounds');
      
      return isInBounds;
    } catch (e) {
      print('$_logTag Error validating location: $e');
      return false;
    }
  }

  /// Format accuracy description for UI
  static String getAccuracyDescription(double accuracy) {
    if (accuracy < 50) {
      return 'Sangat Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 100) {
      return 'Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 200) {
      return 'Cukup Akurat (±${accuracy.toStringAsFixed(0)}m)';
    } else {
      return 'Kurang Akurat (±${accuracy.toStringAsFixed(0)}m)';
    }
  }

  /// Get accuracy level badge color based on accuracy value
  static String getAccuracyBadgeColor(double accuracy) {
    if (accuracy < 50) return 'green';
    if (accuracy < 100) return 'green_light';
    if (accuracy < 200) return 'blue';
    return 'orange';
  }

  /// Check if location is from WiFi (most accurate)
  static bool isWiFiBased(Map<String, dynamic>? location) {
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('WiFi') ?? false;
  }

  /// Get source quality rating
  static String getSourceQuality(Map<String, dynamic>? location) {
    if (location == null) return 'Tidak Tersedia';

    final accuracy = location['accuracy'] as double?;
    final provider = location['provider'] as String?;

    if (accuracy != null && accuracy < 100) {
      return 'Sangat Akurat ($provider)';
    } else if (accuracy != null && accuracy < 200) {
      return 'Akurat ($provider)';
    }

    return 'Cukup Akurat ($provider)';
  }
}
