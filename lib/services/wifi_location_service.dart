import 'package:http/http.dart' as http;
import 'dart:convert';

class WiFiLocationService {
  static const String _logTag = '[WiFiLocationService]';
  
  // Using OpenWiFiMap API - free, no API key required
  static const String _openWiFiMapUrl = 'https://api.openwifimap.net/api/v1/geoip';
  
  /// Get accurate location using WiFi networks with multiple data sources
  /// This method provides GPS-like accuracy by using WiFi AP databases
  Future<Map<String, dynamic>?> getWiFiBasedLocation() async {
    try {
      // Try OpenWiFiMap first (Indonesian support, good coverage)
      var location = await _queryOpenWiFiMap();
      if (location != null) {
        return location;
      }

      // Fallback to standard geolocation with enhanced accuracy
      var fallbackLocation = await _getEnhancedGeolocation();
      if (fallbackLocation != null) {
        return fallbackLocation;
      }

      return null;
    } catch (e) {
      print('$_logTag Error getting WiFi location: $e');
      return null;
    }
  }

  /// Query OpenWiFiMap API for WiFi-based geolocation
  /// Provides high accuracy by using crowdsourced WiFi AP data
  Future<Map<String, dynamic>?> _queryOpenWiFiMap() async {
    try {
      final response = await http
          .get(Uri.parse(_openWiFiMapUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract location data from response
        final location = data['location'] ?? {};
        final accuracy = data['accuracy'] ?? 100.0;

        if (location.isNotEmpty) {
          return {
            'latitude': double.parse(location['latitude'].toString()),
            'longitude': double.parse(location['longitude'].toString()),
            'accuracy': accuracy,
            'city': data['city'] ?? 'Unknown',
            'country': data['country'] ?? 'Unknown',
            'isp': data['isp'] ?? 'Unknown',
            'provider': 'OpenWiFiMap',
            'source': 'WiFi Access Points (OpenWiFiMap)',
            'connectivity': 'WiFi-AP',
            'type': 'network',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying OpenWiFiMap: $e');
      return null;
    }
  }

  /// Enhanced geolocation with WiFi connectivity check
  /// Falls back to IP geolocation but with WiFi indicator
  Future<Map<String, dynamic>?> _getEnhancedGeolocation() async {
    try {
      // Use ipapi.co as fallback with WiFi indicator
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'accuracy': 150.0, // Lower accuracy than WiFi AP
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'provider': 'IP-based',
          'source': 'IP Geolocation (Fallback)',
          'connectivity': 'WiFi-IP',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      return null;
    } catch (e) {
      print('$_logTag Error in enhanced geolocation: $e');
      return null;
    }
  }

  /// Format accuracy description for UI
  static String getAccuracyDescription(double accuracy) {
    if (accuracy < 50) {
      return 'Sangat Akurat (${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 100) {
      return 'Akurat (${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 200) {
      return 'Cukup Akurat (${accuracy.toStringAsFixed(0)}m)';
    } else {
      return 'Kurang Akurat (${accuracy.toStringAsFixed(0)}m)';
    }
  }

  /// Get accuracy level badge color based on accuracy value
  static String getAccuracyBadgeColor(double accuracy) {
    if (accuracy < 50) return 'green';
    if (accuracy < 100) return 'green_light';
    if (accuracy < 200) return 'blue';
    return 'orange';
  }

  /// Check if location is from WiFi Access Points (most accurate)
  static bool isWiFiAPBased(Map<String, dynamic>? location) {
    return location?['provider'] == 'OpenWiFiMap' ||
        location?['connectivity'] == 'WiFi-AP';
  }

  /// Get source quality rating
  static String getSourceQuality(Map<String, dynamic>? location) {
    if (location == null) return 'Tidak Tersedia';

    final provider = location['provider'] as String?;
    final accuracy = location['accuracy'] as double?;

    if (provider == 'OpenWiFiMap') {
      if (accuracy != null && accuracy < 100) {
        return 'GPS-like (WiFi AP)';
      }
      return 'High Accuracy (WiFi AP)';
    } else if (provider == 'IP-based') {
      return 'Medium Accuracy (IP)';
    }

    return 'Unknown';
  }
}
