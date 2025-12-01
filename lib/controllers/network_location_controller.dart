import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/services/location_service_v2.dart';
import '../services/network_location_service.dart';

/// Enhanced controller untuk Network Provider Location Tracker
/// Dengan accuracy improvements dan better tracking
class NetworkLocationController extends GetxController {
  final LocationServiceV2 _locationService = LocationServiceV2();
  final NetworkLocationService _networkLocationService = NetworkLocationService();

  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final Rx<Map<String, dynamic>?> _networkLocation = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isTracking = false.obs;
  final Rx<LocationPermission> _permissionStatus =
      LocationPermission.denied.obs;

  final RxDouble _currentAccuracy = 0.0.obs;
  final RxString _accuracyLevel = 'unknown'.obs;

  // FlutterMap Controller
  MapController? _mapController;
  bool _isDisposed = false;

  // Map center position dan zoom
  final Rx<LatLng> _mapCenter = Rx<LatLng>(
    const LatLng(-6.2088, 106.8456), // Jakarta default
  );
  final RxDouble _mapZoom = 15.0.obs;

  // Stream subscription
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  Position? get currentPosition => _currentPosition.value;
  Map<String, dynamic>? get networkLocation => _networkLocation.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isTracking => _isTracking.value;
  LocationPermission get permissionStatus => _permissionStatus.value;
  double get currentAccuracy => _currentAccuracy.value;
  String get accuracyLevel => _accuracyLevel.value;

  MapController get mapController {
    if (_mapController == null || _isDisposed) {
      try {
        _mapController?.dispose();
      } catch (e) {
        // Ignore error saat dispose
      }
      _mapController = MapController();
      _isDisposed = false;
    }
    return _mapController!;
  }

  bool get isMapControllerReady => _mapController != null && !_isDisposed;
  LatLng get mapCenter => _mapCenter.value;
  double get mapZoom => _mapZoom.value;

  double? get latitude => _networkLocation.value?['latitude'] ?? _currentPosition.value?.latitude;
  double? get longitude => _networkLocation.value?['longitude'] ?? _currentPosition.value?.longitude;
  double? get accuracy => _networkLocation.value?['accuracy'] ?? _currentPosition.value?.accuracy;
  double? get altitude => _currentPosition.value?.altitude;
  double? get speed => _currentPosition.value?.speed;
  DateTime? get timestamp => _currentPosition.value?.timestamp;

  @override
  void onInit() {
    super.onInit();
    _isDisposed = false;
    try {
      _mapController?.dispose();
    } catch (e) {
      // Ignore error
    }
    _mapController = MapController();
    _initializeLocation();
  }

  @override
  void onClose() {
    _isDisposed = true;
    _stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      _mapController?.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing map controller: $e');
      }
    } finally {
      _mapController = null;
    }

    super.onClose();
  }

  bool _canUseMapController() {
    return !_isDisposed && _mapController != null;
  }

  Future<void> _initializeLocation() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] _initializeLocation() called');
      print('🌐 [NETWORK CONTROLLER] Will fetch FRESH position with accuracy');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      _permissionStatus.value = await _locationService.checkPermission();

      if (_permissionStatus.value == LocationPermission.denied ||
          _permissionStatus.value == LocationPermission.deniedForever) {
        await requestPermission();
      }

      if (kDebugMode) {
        print('🌐 [NETWORK CONTROLLER] Fetching network location...');
      }
      await getCurrentNetworkLocation();

      _isLoading.value = false;
    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Initialization error: ${e.toString()}');
        print('❌ [NETWORK CONTROLLER] Stack trace: $stackTrace');
      }
    }
  }

  /// Get current network location dengan accuracy tracking
  Future<void> getCurrentNetworkLocation() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] getCurrentNetworkLocation() called');
      print('🌐 [NETWORK CONTROLLER] Requesting network provider location...');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Get network location (with force refresh)
      final location = await _networkLocationService.getLocationFromNetwork(
        forceRefresh: true,
      );

      if (location != null) {
        _networkLocation.value = location;
        
        final acc = location['accuracy'] as double?;
        if (acc != null) {
          _currentAccuracy.value = acc;
          _accuracyLevel.value = NetworkLocationService.getAccuracyLevel(acc);
        }

        // Update map
        _updateMapPosition(
          location['latitude'] as double,
          location['longitude'] as double,
        );

        _errorMessage.value = '';

        if (kDebugMode) {
          print('✅ [NETWORK CONTROLLER] Network location received');
          print('🌐 [NETWORK CONTROLLER] Accuracy: ${location['accuracy']}m');
          print('🌐 [NETWORK CONTROLLER] Source: ${location['connectivity']}');
          print('🌐 [NETWORK CONTROLLER] Lat: ${location['latitude']}, Lng: ${location['longitude']}');
        }
      } else {
        throw Exception('Failed to get network location: Location is null');
      }

      _isLoading.value = false;
    } on PermissionDeniedException catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] PermissionDeniedException: ${e.toString()}');
      }
    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Error: ${e.toString()}');
        print('❌ [NETWORK CONTROLLER] Stack trace: $stackTrace');
      }
    }
  }

  Future<void> requestPermission() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      bool granted = await _locationService.requestPermission(
        requireGps: false,
      );
      _permissionStatus.value = await _locationService.checkPermission();

      if (!granted) {
        final status = await _locationService.checkPermission();
        if (status == LocationPermission.deniedForever) {
          throw PermissionDeniedException(
            'Location permission permanently denied',
          );
        } else {
          throw PermissionDeniedException('Location permission denied');
        }
      } else {
        _errorMessage.value = '';
        await getCurrentNetworkLocation();
      }

      _isLoading.value = false;
    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Request permission error: ${e.toString()}');
        print('❌ [NETWORK CONTROLLER] Stack trace: $stackTrace');
      }
    }
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Keep old method for backward compatibility
  Future<void> getCurrentPosition() async {
    await getCurrentNetworkLocation();
  }

  Future<void> getLastKnownPosition() async {
    try {
      Position? position = await _locationService.getLastKnownPosition();

      if (position != null) {
        _currentPosition.value = position;
        _updateMapPosition(position.latitude, position.longitude);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get last known position error: $e');
      }
    }
  }

  Future<void> startTracking() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] startTracking() called');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      bool hasPermission = await _locationService.isPermissionGranted();
      if (!hasPermission) {
        hasPermission = await _locationService.requestPermission(
          requireGps: false,
        );
      }

      if (!hasPermission) {
        final status = await _locationService.checkPermission();
        if (status == LocationPermission.deniedForever) {
          throw PermissionDeniedException(
            'Location permission permanently denied',
          );
        } else {
          throw PermissionDeniedException('Location permission denied');
        }
      }

      _isTracking.value = true;
      _errorMessage.value = '';

      Stream<Position>? positionStream = _locationService.getPositionStream(
        useGps: false,
        distanceFilter: 10,
      );

      if (positionStream != null) {
        _positionSubscription?.cancel();
        _positionSubscription = positionStream.listen(
          (Position position) {
            _currentPosition.value = position;
            _updateMapPosition(position.latitude, position.longitude);
          },
          onError: (error) {
            _errorMessage.value = error.toString();
            if (kDebugMode) {
              print('❌ [NETWORK CONTROLLER] Position stream error: ${error.toString()}');
            }
          },
        );
      } else {
        throw Exception('Failed to start position stream');
      }
    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isTracking.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Start tracking error: ${e.toString()}');
        print('❌ [NETWORK CONTROLLER] Stack trace: $stackTrace');
      }
    }
  }

  void _stopTracking() {
    _isTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationService.stopPositionStream();
  }

  void stopTracking() {
    _stopTracking();
  }

  void _updateMapPosition(double latitude, double longitude) {
    if (_isDisposed || !_canUseMapController()) return;

    final newCenter = LatLng(latitude, longitude);
    _mapCenter.value = newCenter;

    try {
      _mapController?.move(newCenter, _mapZoom.value);
    } catch (e) {
      if (kDebugMode) {
        print('Map controller not ready yet: $e');
      }
    }
  }

  void updateMapCenter(LatLng center, double zoom) {
    if (_isDisposed) return;
    _mapCenter.value = center;
    _mapZoom.value = zoom;
  }

  void setZoom(double zoom) {
    if (_isDisposed || !_canUseMapController()) return;

    _mapZoom.value = zoom;
    if (latitude != null && longitude != null) {
      try {
        _mapController?.move(
          LatLng(latitude!, longitude!),
          zoom,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Map controller not ready for zoom: $e');
        }
      }
    }
  }

  void zoomIn() {
    final newZoom = (_mapZoom.value + 1).clamp(3.0, 18.0);
    setZoom(newZoom);
  }

  void zoomOut() {
    final newZoom = (_mapZoom.value - 1).clamp(3.0, 18.0);
    setZoom(newZoom);
  }

  void moveToCurrentPosition() {
    if (_isDisposed || !_canUseMapController()) return;

    if (latitude != null && longitude != null) {
      try {
        final center = LatLng(latitude!, longitude!);
        _mapController?.move(center, _mapZoom.value);
        _mapCenter.value = center;
      } catch (e) {
        if (kDebugMode) {
          print('Map controller not ready for move: $e');
        }
      }
    }
  }

  Future<void> refreshPosition() async {
    _networkLocationService.clearCache();
    await getCurrentNetworkLocation();
  }

  void resetMapController() {
    try {
      _mapController?.dispose();
    } catch (e) {
      // Ignore error
    }
    _mapController = MapController();
    _isDisposed = false;
  }

  Future<void> toggleTracking() async {
    if (_isTracking.value) {
      stopTracking();
    } else {
      await startTracking();
    }
  }

  Map<String, dynamic> getErrorAction() {
    final error = _errorMessage.value.toLowerCase();

    if (error.contains('permanently denied') || 
        error.contains('deniedforever')) {
      return {
        'label': 'Buka Pengaturan',
        'icon': Icons.settings,
        'action': openAppSettings,
      };
    }

    if (error.contains('permission denied') || 
        error.contains('permission')) {
      return {
        'label': 'Berikan Izin Lokasi',
        'icon': Icons.location_on,
        'action': requestPermission,
      };
    }

    if (error.contains('timeout') || 
        error.contains('network') ||
        error.contains('unavailable')) {
      return {
        'label': 'Coba Lagi',
        'icon': Icons.refresh,
        'action': getCurrentNetworkLocation,
      };
    }

    return {
      'label': 'Coba Lagi',
      'icon': Icons.refresh,
      'action': getCurrentNetworkLocation,
    };
  }

  String? get selectedAddressForBooking {
    return _networkLocation.value?['address'] ?? 
           _networkLocation.value?['city'];
  }

  double? get selectedLatitudeForBooking => latitude;
  double? get selectedLongitudeForBooking => longitude;
}
