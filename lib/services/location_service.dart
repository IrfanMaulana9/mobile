import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking.dart';

class LocationService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  static const double malangMinLat = -8.15;
  static const double malangMaxLat = -7.65;
  static const double malangMinLng = 112.50;
  static const double malangMaxLng = 112.85;

  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        '$_nominatimUrl/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FlutterCleaningApp/1.0'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Geocoding timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['address']['road'] ?? json['display_name'] ?? 'Unknown Address';
      }
      return 'Unknown Address';
    } catch (e) {
      print('[v0] Error reverse geocoding: $e');
      return 'Address not available';
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final uri = Uri.parse(
        '$_nominatimUrl/search?format=json&q=$query&bounded=1&viewbox=$malangMinLng,$malangMaxLat,$malangMaxLng,$malangMinLat&limit=10',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FlutterCleaningApp/1.0'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Search timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        return results
            .map((r) => {
                  'lat': double.parse(r['lat']),
                  'lon': double.parse(r['lon']),
                  'display_name': r['display_name'],
                })
            .toList();
      }
      return [];
    } catch (e) {
      print('[v0] Error searching places: $e');
      return [];
    }
  }
}
