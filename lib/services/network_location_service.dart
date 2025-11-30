import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';
  static const String _ipGeolocationUrl = 'https://ipapi.co/json/';

  /// Get location from network (IP-based geolocation)
  /// This provides approximate location when GPS is unavailable
  Future<Map<String, dynamic>?> getLocationFromNetwork() async {
    try {
      final response = await http.get(
        Uri.parse(_ipGeolocationUrl),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Network location timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = {
          'latitude': double.parse(data['latitude'].toString()),
          'longitude': double.parse(data['longitude'].toString()),
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'country': data['country'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'type': 'network',
        };
        
        print('$_logTag Network location: ${location['city']}, ${location['region']}');
        return location;
      }
      return null;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Get location quality description
  static String getQualityDescription(String locationType) {
    switch (locationType) {
      case 'network':
        return 'Berbasis Jaringan (Kurang Akurat)';
      case 'gps':
        return 'GPS (Sangat Akurat)';
      default:
        return 'Tidak Diketahui';
    }
  }
}
