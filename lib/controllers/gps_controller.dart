import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_tracking_service.dart';
import '../services/network_location_service.dart';
import '../services/location_service.dart';
import '../models/location_history.dart';

class GPSController extends GetxController {
  static const String _logTag = '[GPSController]';
  
  final gpsService = GPSTrackingService();
  final networkService = NetworkLocationService();
  final locationService = LocationService();

  // Observable values
  final currentPosition = Rxn<Position>();
  final currentAddress = ''.obs;
  final isTracking = false.obs;
  final isGPSInitialized = false.obs;
  final isLoading = false.obs;
  final accuracy = ''.obs;
  final speed = 0.0.obs;
  final altitude = 0.0.obs;
  final totalDistance = 0.0.obs;
  final locationType = 'gps'.obs;
  final locationHistory = <LocationHistoryEntry>[].obs;
  final networkLocation = Rxn<Map<String, dynamic>>();

  @override
  Future<void> onInit() async {
    super.onInit();
    print('$_logTag Initializing...');
    print('$_logTag Ready for on-demand location access');
  }

  /// Initialize GPS and request permissions (called on-demand)
  Future<void> initializeGPS() async {
    isLoading.value = true;
    try {
      final success = await gpsService.initializeGPS();
      isGPSInitialized.value = success;
      
      if (success) {
        await getCurrentLocation();
        print('$_logTag GPS initialized successfully');
      } else {
        print('$_logTag GPS initialization failed');
      }
    } catch (e) {
      print('$_logTag Error during initialization: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current location once
  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    try {
      final position = await gpsService.getCurrentLocation();
      
      if (position != null) {
        currentPosition.value = position;
        _updateLocationMetrics(position);
        
        // Reverse geocode to get address
        final address = await locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        currentAddress.value = address;
        
        locationType.value = 'gps';
        
        // Add to history
        _addToHistory(
          LocationHistoryEntry.fromPosition(
            position,
            address: address,
            locationType: 'gps',
          ),
        );
        
        print('$_logTag Current location fetched: $address');
      }
    } catch (e) {
      print('$_logTag Error getting current location: $e');
      Get.snackbar('Error', 'Gagal mendapatkan lokasi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get location from network (fallback)
  Future<void> getNetworkLocation() async {
    try {
      final location = await networkService.getLocationFromNetwork();
      
      if (location != null) {
        networkLocation.value = location;
        currentAddress.value = '${location['city']}, ${location['region']}';
        locationType.value = 'network';
        
        print('$_logTag Network location obtained: ${location['city']}');
      }
    } catch (e) {
      print('$_logTag Error getting network location: $e');
    }
  }

  /// Start live tracking
  Future<void> startLiveTracking() async {
    if (isTracking.value) return;
    
    if (!isGPSInitialized.value) {
      Get.snackbar('Error', 'GPS belum diinisialisasi');
      return;
    }

    isTracking.value = true;
    print('$_logTag Live tracking started');

    try {
      final stream = gpsService.startLiveTracking(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
      );

      stream.listen(
        (position) {
          currentPosition.value = position;
          _updateLocationMetrics(position);
          
          // Add to history
          _addToHistory(
            LocationHistoryEntry.fromPosition(
              position,
              locationType: 'gps',
            ),
          );
          
          print('$_logTag Position update: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          print('$_logTag Stream error: $error');
          isTracking.value = false;
          Get.snackbar('Error', 'Tracking error: $error');
        },
      );
    } catch (e) {
      print('$_logTag Error starting tracking: $e');
      isTracking.value = false;
      Get.snackbar('Error', 'Gagal memulai tracking: $e');
    }
  }

  /// Stop live tracking
  Future<void> stopLiveTracking() async {
    await gpsService.stopLiveTracking();
    isTracking.value = false;
    print('$_logTag Live tracking stopped');
  }

  /// Update location metrics
  void _updateLocationMetrics(Position position) {
    accuracy.value = position.accuracy.toStringAsFixed(1);
    speed.value = position.speed;
    altitude.value = position.altitude;
  }

  /// Add location to history and calculate distance
  void _addToHistory(LocationHistoryEntry entry) {
    if (locationHistory.isNotEmpty) {
      final lastEntry = locationHistory.last;
      final distance = GPSTrackingService.calculateDistance(
        lastEntry.latitude,
        lastEntry.longitude,
        entry.latitude,
        entry.longitude,
      );
      totalDistance.value += distance;
    }
    
    locationHistory.add(entry);
  }

  /// Clear location history
  void clearHistory() {
    locationHistory.clear();
    totalDistance.value = 0.0;
    print('$_logTag Location history cleared');
  }

  /// Get location type description
  String getLocationTypeDescription() {
    return NetworkLocationService.getQualityDescription(locationType.value);
  }

  /// Get accuracy description
  String getAccuracyDescription() {
    final position = currentPosition.value;
    if (position == null) return 'N/A';
    
    if (GPSTrackingService.isAccurateLocation(position, minAccuracy: 10)) {
      return 'Akurat';
    } else if (GPSTrackingService.isAccurateLocation(position, minAccuracy: 50)) {
      return 'Cukup Akurat';
    } else {
      return 'Kurang Akurat';
    }
  }

  @override
  void onClose() {
    stopLiveTracking();
    print('$_logTag Disposed');
    super.onClose();
  }
}
