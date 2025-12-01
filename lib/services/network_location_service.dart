import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'wifi_location_service.dart';

class NetworkLocationService {
  static const String _logTag = '[NetworkLocationService]';

  final _wifiService = WiFiLocationService();

  /// Get location from network with WiFi prioritized for accuracy
  Future<Map<String, dynamic>?> getLocationFromNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // If connected to WiFi, try WiFi-based geolocation first (most accurate)
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        print('$_logTag Connected to WiFi, trying WiFi-based geolocation...');
        final wifiLocation = await _wifiService.getWiFiBasedLocation();
        if (wifiLocation != null) {
          print('$_logTag WiFi location obtained successfully');
          return wifiLocation;
        }
      }

      print('$_logTag WiFi geolocation failed, cannot proceed without WiFi');
      return null;
    } catch (e) {
      print('$_logTag Error getting network location: $e');
      return null;
    }
  }

  /// Get location quality description with accuracy info
  static String getQualityDescription(String locationType, {String? source}) {
    switch (locationType) {
      case 'network':
        return source?.contains('WiFi') ?? false
            ? 'WiFi-based (Sangat Akurat)'
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

    if (connectivity?.contains('WiFi') ?? false) {
      return '$provider (WiFi-based)';
    }

    return source ?? 'Network Provider';
  }

  /// Check if location is from WiFi
  static bool isWiFiBasedLocation(Map<String, dynamic>? location) {
    final connectivity = location?['connectivity'] as String?;
    return connectivity?.contains('WiFi') ?? false;
  }

  /// Check if location is from high-accuracy WiFi
  static bool isHighAccuracyWiFi(Map<String, dynamic>? location) {
    final accuracy = location?['accuracy'] as double?;
    return (accuracy ?? 500) < 150;
  }

  /// Get accuracy in meters
  static double? getAccuracy(Map<String, dynamic>? location) {
    return location?['accuracy'] as double?;
  }
}
