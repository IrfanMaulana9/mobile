import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:math';

class GPSTrackingService {
  static const String _logTag = '[GPSTrackingService]';
  
  Stream<Position>? _positionStream;
  LocationSettings? _locationSettings;

  /// Initialize GPS tracking with specified accuracy
  Future<bool> initializeGPS() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('$_logTag Location service is disabled');
        return false;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('$_logTag Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('$_logTag Location permissions are denied forever');
        return false;
      }

      print('$_logTag GPS initialized successfully');
      return true;
    } catch (e) {
      print('$_logTag Error initializing GPS: $e');
      return false;
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Location timeout'),
      );
      
      print('$_logTag Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('$_logTag Error getting current location: $e');
      return null;
    }
  }

  /// Start live position stream with specified accuracy
  Stream<Position> startLiveTracking({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10, // Update every 10 meters
  }) {
    _locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );

    print('$_logTag Live tracking started (accuracy: $accuracy, distanceFilter: $distanceFilter m)');
    return _positionStream!;
  }

  /// Stop live position stream
  Future<void> stopLiveTracking() async {
    _positionStream = null;
    print('$_logTag Live tracking stopped');
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    // Using imported dart:math functions - sin, cos, sqrt, atan2
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  /// Check if location has sufficient accuracy
  static bool isAccurateLocation(Position position, {double minAccuracy = 20}) {
    return position.accuracy <= minAccuracy;
  }

  /// Get location accuracy description
  static String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Sangat Rendah (100m+)';
      case LocationAccuracy.low:
        return 'Rendah (10m+)';
      case LocationAccuracy.medium:
        return 'Sedang (5m+)';
      case LocationAccuracy.high:
        return 'Tinggi (1m+)';
      case LocationAccuracy.best:
        return 'Terbaik (<1m)';
      case LocationAccuracy.bestForNavigation:
        return 'Terbaik untuk Navigasi';
      default:
        return 'Tidak Diketahui';
    }
  }
}
