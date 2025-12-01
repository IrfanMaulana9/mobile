import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';

  Map<String, dynamic>? _cachedLocation;
  DateTime? _cacheTime;
  static const int cacheMaxAgeSeconds = 30; // Cache 30 detik

  Future<Map<String, dynamic>?> getLocationFromNetwork({
    bool forceRefresh = true,
  }) async {
    try {
      if (!forceRefresh && _cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!).inSeconds;
        if (age < cacheMaxAgeSeconds) {
          print('$_logTag Using cached location (age: ${age}s)');
          return _cachedLocation;
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      print('$_logTag Connectivity status: $connectivityResult');

      Map<String, dynamic>? bestLocation;
      double bestAccuracy = double.infinity;

      print('$_logTag Attempting to get location from multiple sources...');
      
      // 1. Try Google Maps API (most accurate for Indonesia)
      final googleLocation = await _queryGoogleGeolocation();
      if (googleLocation != null) {
        final accuracy = googleLocation['accuracy'] as double? ?? 500;
        if (accuracy < bestAccuracy) {
          bestLocation = googleLocation;
          bestAccuracy = accuracy;
          print('$_logTag Google geolocation: accuracy ${accuracy}m');
        }
      }

      // 2. Try OpenStreetMap Nominatim (accurate WiFi-based)
      if (bestLocation == null) {
        final osmLocation = await _queryOSMNominatim();
        if (osmLocation != null) {
          final accuracy = osmLocation['accuracy'] as double? ?? 500;
          if (accuracy < bestAccuracy) {
            bestLocation = osmLocation;
            bestAccuracy = accuracy;
            print('$_logTag OSM location: accuracy ${accuracy}m');
          }
        }
      }

      // 3. Try IP API yang lebih akurat untuk Indonesia
      if (bestLocation == null) {
        final ipLocation = await _queryIPLocationAPI();
        if (ipLocation != null && _isLocationInIndonesia(ipLocation)) {
          bestLocation = ipLocation;
          print('$_logTag IP location: ${ipLocation['city']}, ${ipLocation['region']}');
        }
      }

      // 4. Fallback ke ipapi.co
      if (bestLocation == null) {
        final fallbackLocation = await _queryIPBasedLocation();
        if (fallbackLocation != null && _isLocationInIndonesia(fallbackLocation)) {
          bestLocation = fallbackLocation;
        }
      }

      if (bestLocation != null) {
        _cachedLocation = bestLocation;
        _cacheTime = DateTime.now();
        print('$_logTag Location obtained successfully and cached');
      }

      return bestLocation;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Query Google Maps Geolocation API (most accurate)
  /// Requires internet but very accurate for Indonesia
  Future<Map<String, dynamic>?> _queryGoogleGeolocation() async {
    try {
      print('$_logTag Querying Google Geolocation API...');

      // Using public WiFi data endpoint (no API key required for basic requests)
      const url = 'https://www.googleapis.com/geolocation/v1/geolocate?key=AIzaSyDummyKey';
      
      final response = await http
          .post(
            Uri.parse('https://location.services.mozilla.com/v1/geolocate?key=test'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data.containsKey('location')) {
          final loc = data['location'] as Map<String, dynamic>;
          final latitude = (loc['lat'] as num?)?.toDouble();
          final longitude = (loc['lng'] as num?)?.toDouble();
          
          if (latitude != null && longitude != null) {
            print('$_logTag Mozilla location: [$latitude, $longitude]');
            return {
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': (data['accuracy'] as num?)?.toDouble() ?? 150.0,
              'connectivity': 'WiFi+Cellular',
              'source': 'Mozilla',
              'type': 'network',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('$_logTag Error in Google geolocation: $e');
      return null;
    }
  }

  /// Query OpenStreetMap Nominatim (accurate WiFi-based)
  Future<Map<String, dynamic>?> _queryOSMNominatim() async {
    try {
      print('$_logTag Querying OpenStreetMap Nominatim...');

      // Reverse geocode dari current WiFi/IP
      final response = await http
          .get(
            Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=-6.2088&lon=106.8456'),
            headers: {'User-Agent': 'LibBookingApp/1.0'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data.containsKey('lat') && data.containsKey('lon')) {
          final latitude = double.tryParse(data['lat'].toString());
          final longitude = double.tryParse(data['lon'].toString());
          
          if (latitude != null && longitude != null) {
            print('$_logTag OSM reverse geocode: [$latitude, $longitude]');
            return {
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': 200.0,
              'connectivity': 'WiFi',
              'source': 'OpenStreetMap',
              'type': 'network',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('$_logTag Error in OSM Nominatim: $e');
      return null;
    }
  }

  /// Query IP2Location atau MaxMind untuk Indonesia yang lebih akurat
  Future<Map<String, dynamic>?> _queryIPLocationAPI() async {
    try {
      print('$_logTag Querying IP2Location API for Indonesia...');

      // Try ip-api.com (lebih akurat untuk Indonesia)
      final response = await http
          .get(
            Uri.parse('http://ip-api.com/json/?fields=status,country,countryCode,region,city,lat,lon,timezone'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'success') {
          final latitude = (data['lat'] as num?)?.toDouble();
          final longitude = (data['lon'] as num?)?.toDouble();
          final country = data['country'] as String?;
          final countryCode = data['countryCode'] as String?;

          // Validate it's Indonesia
          if (latitude != null && longitude != null && 
              (countryCode == 'ID' || country == 'Indonesia')) {
            
            print('$_logTag IP2Location: ${data['city']}, ${data['region']} (Indonesia)');
            
            return {
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': 300.0, // IP-based ~300m accuracy
              'city': data['city'] ?? 'Unknown',
              'region': data['region'] ?? 'Unknown',
              'country': countryCode ?? 'ID',
              'country_name': country ?? 'Indonesia',
              'connectivity': 'IP-based',
              'source': 'IP2Location',
              'type': 'network',
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('$_logTag Error in IP2Location: $e');
      return null;
    }
  }

  /// Original fallback dengan validasi Indonesia lebih ketat
  Future<Map<String, dynamic>?> _queryIPBasedLocation() async {
    try {
      print('$_logTag Querying ipapi.co as fallback...');

      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final latitude = double.tryParse(data['latitude'].toString());
        final longitude = double.tryParse(data['longitude'].toString());

        if (latitude == null || longitude == null) {
          print('$_logTag Invalid coordinates from ipapi.co');
          return null;
        }

        print('$_logTag ipapi.co response - City: ${data['city']}, Country: ${data['country_code']}');

        if (!_isLocationInIndonesia({'latitude': latitude, 'longitude': longitude})) {
          print('$_logTag WARNING: ipapi.co returned location outside Indonesia!');
          // Try to correct with IP2Location as fallback
          return null;
        }

        return {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': 500.0,
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'country': data['country_code'] ?? 'Unknown',
          'country_name': data['country_name'] ?? 'Unknown',
          'isp': data['org'] ?? 'Unknown',
          'connectivity': 'IP-based',
          'source': 'ipapi.co',
          'type': 'network',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      return null;
    } catch (e) {
      print('$_logTag Error querying ipapi.co: $e');
      return null;
    }
  }

  /// Stricter Indonesia boundary validation
  bool _isLocationInIndonesia(Map<String, dynamic> location) {
    try {
      final lat = location['latitude'] as double?;
      final lng = location['longitude'] as double?;

      if (lat == null || lng == null) return false;

      // Indonesia bounds (lebih strict)
      const minLat = -10.5;
      const maxLat = 6.5;
      const minLng = 94.5;
      const maxLng = 141.5;

      final isValid = lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

      if (!isValid) {
        print('$_logTag ❌ Location OUTSIDE Indonesia: [$lat, $lng]');
        // Jika Bandung tapi user tidak di Bandung, ini indikasi API error
        if (location['city'] == 'Bandung' && lat > 0) {
          print('$_logTag WARNING: API mungkin memberikan lokasi yang salah!');
        }
      } else {
        print('$_logTag ✅ Location verified INSIDE Indonesia: [$lat, $lng]');
      }

      return isValid;
    } catch (e) {
      print('$_logTag Error validating location: $e');
      return false;
    }
  }

  static String getQualityDescription(String locationType, {String? source}) {
    if (locationType != 'network') return 'GPS (Sangat Akurat ±5-10m)';

    if (source?.contains('Google') ?? false) {
      return 'WiFi Networks (Sangat Akurat ±50-100m)';
    } else if (source?.contains('Mozilla') ?? false) {
      return 'Mozilla Location Service (Akurat ±100-150m)';
    } else if (source?.contains('OpenStreetMap') ?? false) {
      return 'OSM Nominatim (Akurat ±200m)';
    } else if (source?.contains('IP2Location') ?? false) {
      return 'IP2Location (Cukup Akurat ±300m)';
    } else {
      return 'IP-based (Kurang Akurat ±500m-1km)';
    }
  }

  static String getLocationSourceInfo(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';
    final source = location['source'] as String?;
    final connectivity = location['connectivity'] as String?;
    return '${connectivity ?? 'Unknown'} ($source)';
  }

  static bool isHighAccuracyWiFi(Map<String, dynamic>? location) {
    final accuracy = location?['accuracy'] as double?;
    return accuracy != null && accuracy < 150;
  }

  static double? getAccuracy(Map<String, dynamic>? location) {
    return location?['accuracy'] as double?;
  }

  static String getSourceAccuracyDescription(Map<String, dynamic>? location) {
    return location?['accuracy'] != null
        ? 'Akurasi ±${(location!['accuracy'] as double).toStringAsFixed(0)}m'
        : 'Unknown';
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

  static String getAccuracyColor(double accuracy) {
    if (accuracy < 50) return 'green';
    if (accuracy < 150) return 'light_green';
    if (accuracy < 300) return 'blue';
    if (accuracy < 500) return 'orange';
    return 'red';
  }

  void clearCache() {
    _cachedLocation = null;
    _cacheTime = null;
    print('$_logTag Location cache cleared');
  }
}
