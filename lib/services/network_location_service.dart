import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'wifi_location_service.dart';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  
  static const String _ipGeolocationUrl = 'https://ipapi.co/json/';
  static const String _ipInfoUrl = 'https://ipinfo.io/json';
  static const String _geoIpUrl = 'https://geoip.com/json/';

  final _wifiService = WiFiLocationService();

  /// Get location from network with WiFi AP prioritized for accuracy
  /// This method now prioritizes WiFi Access Point data over IP-based geolocation
  Future<Map<String, dynamic>?> getLocationFromNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // If connected to WiFi, try WiFi-based geolocation first (most accurate)
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        print('$_logTag Connected to WiFi, trying WiFi AP geolocation...');
        final wifiLocation = await _wifiService.getWiFiBasedLocation();
        if (wifiLocation != null) {
          return wifiLocation;
        }
      }

      // Fallback to IP-based geolocation with multiple sources
      print('$_logTag WiFi geolocation failed, falling back to IP-based...');
      final location = await _getIPBasedLocation();
      if (location != null) {
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Get IP-based geolocation with fallback sources
  Future<Map<String, dynamic>?> _getIPBasedLocation() async {
    try {
      // Try primary API
      var location = await _queryIPGeolocation(_ipGeolocationUrl);
      if (location != null) {
        location['source'] = 'IP Geolocation (Primary)';
        return location;
      }

      print('$_logTag Primary API failed, trying IPInfo');
      // Fallback to second API
      location = await _queryIPInfo(_ipInfoUrl);
      if (location != null) {
        location['source'] = 'IPInfo (Fallback)';
        return location;
      }

      print('$_logTag IPInfo failed, trying GeoIP');
      // Fallback to third API
      location = await _queryGeoIP(_geoIpUrl);
      if (location != null) {
        location['source'] = 'GeoIP (Fallback)';
        return location;
      }

      return null;
    } catch (e) {
      print('$_logTag Error in IP-based geolocation: $e');
      return null;
    }
  }

  /// Query ipapi.co endpoint
  Future<Map<String, dynamic>?> _queryIPGeolocation(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('IP Geolocation timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'accuracy': 500.0, // Low accuracy for IP-based
          'city': data['city'] ?? 'Unknown',
          'region': data['region_code'] ?? data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? data['country_name'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'type': 'network',
          'provider': 'IP-based',
          'connectivity': 'Mobile/IP',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying ipapi.co: $e');
      return null;
    }
  }

  /// Query IPInfo endpoint
  Future<Map<String, dynamic>?> _queryIPInfo(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('IPInfo timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loc = data['loc']?.split(',') ?? [];

        if (loc.length == 2) {
          return {
            'latitude': double.parse(loc[0]),
            'longitude': double.parse(loc[1]),
            'accuracy': 500.0,
            'city': data['city'] ?? 'Unknown',
            'region': data['region'] ?? 'Unknown',
            'country': data['country'] ?? 'Unknown',
            'isp': data['org'] ?? 'Unknown',
            'type': 'network',
            'provider': 'IP-based',
            'connectivity': 'Mobile/IP',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying IPInfo: $e');
      return null;
    }
  }

  /// Query GeoIP endpoint
  Future<Map<String, dynamic>?> _queryGeoIP(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('GeoIP timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'accuracy': 500.0,
          'city': data['city'] ?? 'Unknown',
          'region': data['region_name'] ?? data['state'] ?? 'Unknown',
          'country': data['country_code'] ?? data['country_name'] ?? 'Unknown',
          'isp': data['isp'] ?? 'Unknown',
          'type': 'network',
          'provider': 'IP-based',
          'connectivity': 'Mobile/IP',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying GeoIP: $e');
      return null;
    }
  }

  /// Get location quality description with accuracy info
  static String getQualityDescription(String locationType, {String? source}) {
    switch (locationType) {
      case 'network':
        return source?.contains('WiFi') ?? false
            ? 'WiFi AP-based (Sangat Akurat)'
            : 'IP-based (Kurang Akurat)';
      case 'gps':
        return 'GPS (Sangat Akurat)';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get location source info for display
  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';

    final source = location['source'] as String?;
    final provider = location['provider'] as String?;
    final connectivity = location['connectivity'] as String?;

    if (provider == 'OpenWiFiMap' || connectivity == 'WiFi-AP') {
      return 'WiFi AP-based (GPS-like Accuracy)';
    } else if (connectivity?.contains('WiFi') ?? false) {
      return 'WiFi-based (High Accuracy)';
    } else if (source?.contains('Primary') ?? false) {
      return 'IP-based Primary';
    } else if (source?.contains('Fallback') ?? false) {
      return 'IP-based Fallback';
    }

    return source ?? 'Network Provider';
  }

  /// Check if location is from WiFi (WiFi AP or WiFi IP)
  static bool isWiFiBasedLocation(Map<String, dynamic>? location) {
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('WiFi') ?? false;
  }

  /// Check if location is from high-accuracy WiFi AP
  static bool isHighAccuracyWiFi(Map<String, dynamic>? location) {
    return location?['provider'] == 'OpenWiFiMap' ||
        location?['connectivity'] == 'WiFi-AP';
  }

  /// Get accuracy in meters
  static double? getAccuracy(Map<String, dynamic>? location) {
    return location?['accuracy'] as double?;
  }
}
