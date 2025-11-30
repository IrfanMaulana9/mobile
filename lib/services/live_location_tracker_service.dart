import 'package:geolocator/geolocator.dart';
import '../models/location_history.dart';

class LiveLocationTrackerService {
  static const String _logTag = '[LiveLocationTrackerService]';
  
  Stream<Position>? _positionStream;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  final List<LocationHistoryEntry> _trackingHistory = [];

  /// Start live tracking with specified parameters
  Stream<Position> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 5, // meters
    Duration timeInterval = const Duration(seconds: 1),
  }) {
    print('$_logTag Starting live tracking...');
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: timeInterval,
      ),
    );

    _positionStream!.listen((position) {
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distance;
      }
      _lastPosition = position;
    });

    return _positionStream!;
  }

  /// Stop live tracking
  Future<void> stopTracking() async {
    print('$_logTag Stopping live tracking');
    _positionStream = null;
  }

  /// Add entry to tracking history
  void addToHistory(LocationHistoryEntry entry) {
    _trackingHistory.add(entry);
  }

  /// Get tracking history
  List<LocationHistoryEntry> getTrackingHistory() {
    return List.from(_trackingHistory);
  }

  /// Clear tracking history
  void clearHistory() {
    _trackingHistory.clear();
    _totalDistance = 0.0;
    _lastPosition = null;
    print('$_logTag Tracking history cleared');
  }

  /// Get total distance traveled in km
  double getTotalDistance() {
    return _totalDistance / 1000;
  }

  /// Check if currently tracking
  bool isTracking() {
    return _positionStream != null;
  }
}
