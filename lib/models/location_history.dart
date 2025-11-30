import 'package:geolocator/geolocator.dart';

class LocationHistoryEntry {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? speed;
  final double? altitude;
  final String? address;
  final String locationType; // 'gps' or 'network'

  LocationHistoryEntry({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.altitude,
    this.address,
    this.locationType = 'gps',
  });

  /// Convert from Position object
  factory LocationHistoryEntry.fromPosition(Position position, {String locationType = 'gps', String? address}) {
    return LocationHistoryEntry(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
      speed: position.speed,
      altitude: position.altitude,
      address: address,
      locationType: locationType,
    );
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
      'address': address,
      'locationType': locationType,
    };
  }

  /// Create from Map
  factory LocationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return LocationHistoryEntry(
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracy: map['accuracy'],
      timestamp: DateTime.parse(map['timestamp']),
      speed: map['speed'],
      altitude: map['altitude'],
      address: map['address'],
      locationType: map['locationType'] ?? 'gps',
    );
  }
}
