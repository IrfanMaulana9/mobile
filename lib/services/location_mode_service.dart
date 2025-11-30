import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'network_location_service.dart';
import 'gps_tracking_service.dart';

class LocationModeService {
  static const String _logTag = '[LocationModeService]';

  final locationService = LocationService();
  final networkService = NetworkLocationService();
  final gpsService = GPSTrackingService();

  /// Get current location using specified mode
  /// Modes: 'gps', 'network', 'hybrid' (tries GPS first, fallback to network)
  Future<LocationData?> getCurrentLocation(String mode) async {
    try {
      switch (mode) {
        case 'gps':
          return await _getGPSLocation();
        case 'network':
          return await _getNetworkLocation();
        case 'hybrid':
        default:
          return await _getHybridLocation();
      }
    } catch (e) {
      print('$_logTag Error getting location with mode $mode: $e');
      return null;
    }
  }

  /// Get location from GPS only
  Future<LocationData?> _getGPSLocation() async {
    try {
      print('$_logTag Getting GPS location...');
      
      final hasPermission = await _checkGPSPermission();
      if (!hasPermission) {
        print('$_logTag GPS permission denied');
        return null;
      }

      final position = await gpsService.getCurrentLocation();
      if (position == null) return null;

      final address = await locationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        locationType: 'gps',
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('$_logTag GPS location error: $e');
      return null;
    }
  }

  /// Get location from network (IP-based)
  Future<LocationData?> _getNetworkLocation() async {
    try {
      print('$_logTag Getting network location...');
      
      final location = await networkService.getLocationFromNetwork();
      if (location == null) return null;

      return LocationData(
        latitude: location['latitude'],
        longitude: location['longitude'],
        address: '${location['city']}, ${location['region']}',
        locationType: 'network',
        accuracy: 5000, // Network accuracy is approximately 5km
        altitude: 0,
        speed: 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('$_logTag Network location error: $e');
      return null;
    }
  }

  /// Hybrid mode: Try GPS first, fallback to network
  Future<LocationData?> _getHybridLocation() async {
    print('$_logTag Getting hybrid location...');
    
    final gpsLocation = await _getGPSLocation();
    if (gpsLocation != null) {
      print('$_logTag Hybrid mode: Using GPS location');
      return gpsLocation;
    }

    final networkLocation = await _getNetworkLocation();
    if (networkLocation != null) {
      print('$_logTag Hybrid mode: Falling back to network location');
      return networkLocation;
    }

    print('$_logTag Hybrid mode: Failed to get any location');
    return null;
  }

  /// Check GPS permission
  Future<bool> _checkGPSPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get mode description
  static String getModeDescription(String mode) {
    switch (mode) {
      case 'gps':
        return 'GPS (Sangat Akurat)';
      case 'network':
        return 'Jaringan (Perkiraan)';
      case 'hybrid':
        return 'Hibrida (GPS/Jaringan)';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get mode icon description
  static String getModeIcon(String mode) {
    switch (mode) {
      case 'gps':
        return '📡 GPS';
      case 'network':
        return '🌐 Jaringan';
      case 'hybrid':
        return '🔄 Hibrida';
      default:
        return '❓ Tidak Diketahui';
    }
  }
}

/// Data class for location information
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String locationType; // 'gps', 'network'
  final double accuracy; // in meters
  final double altitude; // in meters
  final double speed; // in m/s
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.locationType,
    this.accuracy = 0,
    this.altitude = 0,
    this.speed = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get accuracy description
  String getAccuracyDescription() {
    if (accuracy < 10) return 'Sangat Akurat';
    if (accuracy < 50) return 'Akurat';
    if (accuracy < 100) return 'Cukup';
    return 'Kurang Akurat';
  }

  /// Get speed in km/h
  double getSpeedKmh() => speed * 3.6;

  /// To JSON for storage
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'locationType': locationType,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'timestamp': timestamp.toIso8601String(),
  };

  /// From JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      locationType: json['locationType'],
      accuracy: json['accuracy'] ?? 0,
      altitude: json['altitude'] ?? 0,
      speed: json['speed'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
