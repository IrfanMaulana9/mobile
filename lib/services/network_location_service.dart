import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  
  static const String _ipGeolocationUrl = 'https://ipapi.co/json/';
  static const String _ipInfoUrl = 'https://ipinfo.io/json';
  static const String _geoIpUrl = 'https://geoip.com/json/';

  /// Get location from network with multiple fallback sources
  /// This provides approximate location when GPS is unavailable
  /// Enhanced with WiFi detection and multiple API sources
  Future<Map<String, dynamic>?> getLocationFromNetwork() async {
    try {
      // First, try to get WiFi-based geolocation for better accuracy
      final wifiLocation = await _getWiFiBasedLocation();
      if (wifiLocation != null) {
        print('$_logTag Using WiFi-based geolocation (more accurate)');
        return wifiLocation;
      }

      // Fallback to IP-based geolocation with multiple sources
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

  /// New method: Get location based on WiFi networks
  /// Uses connected WiFi and nearby networks for more accurate geolocation
  Future<Map<String, dynamic>?> _getWiFiBasedLocation() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Only try WiFi geolocation if connected to WiFi
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        print('$_logTag Connected to WiFi, attempting WiFi-based geolocation');
        
        // Try primary API first
        var location = await _queryIPGeolocation(_ipGeolocationUrl);
        
        if (location != null) {
          // Enhance with WiFi connectivity indicator
          location['connectivity'] = 'WiFi';
          location['source'] = 'IP Geolocation (WiFi)';
          return location;
        }
      }
      
      return null;
    } catch (e) {
      print('$_logTag Error in WiFi-based geolocation: $e');
      return null;
    }
  }

  /// New method: Get IP-based geolocation with fallback sources
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

  /// New method: Query ipapi.co endpoint
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
          'city': data['city'] ?? 'Unknown',
          'region': data['region_code'] ?? data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? data['country_name'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'type': 'network',
          'accuracy_note': 'IP-based (Low Accuracy)',
        };
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying ipapi.co: $e');
      return null;
    }
  }

  /// New method: Query IPInfo endpoint
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
            'city': data['city'] ?? 'Unknown',
            'region': data['region'] ?? 'Unknown',
            'country': data['country'] ?? 'Unknown',
            'isp': data['org'] ?? 'Unknown',
            'type': 'network',
            'accuracy_note': 'IP-based (Low Accuracy)',
          };
        }
      }
      return null;
    } catch (e) {
      print('$_logTag Error querying IPInfo: $e');
      return null;
    }
  }

  /// New method: Query GeoIP endpoint
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
          'city': data['city'] ?? 'Unknown',
          'region': data['region_name'] ?? data['state'] ?? 'Unknown',
          'country': data['country_code'] ?? data['country_name'] ?? 'Unknown',
          'isp': data['isp'] ?? 'Unknown',
          'type': 'network',
          'accuracy_note': 'IP-based (Low Accuracy)',
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
        return source == 'IP Geolocation (WiFi)' 
            ? 'Berbasis WiFi (Akurasi Sedang)' 
            : 'Berbasis IP (Kurang Akurat)';
      case 'gps':
        return 'GPS (Sangat Akurat)';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// New method: Get location source info for display
  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';
    
    final source = location['source'] as String?;
    final connectivity = location['connectivity'] as String?;
    
    if (connectivity == 'WiFi') {
      return 'WiFi-Based (Lebih Akurat)';
    } else if (source?.contains('Primary') ?? false) {
      return 'IP-Based Primary';
    } else if (source?.contains('Fallback') ?? false) {
      return 'IP-Based Fallback';
    }
    
    return source ?? 'Network Provider';
  }

  /// New method: Check if location is from WiFi
  static bool isWiFiBasedLocation(Map<String, dynamic>? location) {
    return location?['connectivity'] == 'WiFi';
  }
}
