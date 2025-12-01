import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/services/location_service_v2.dart';
import '../services/network_location_service.dart';

/// Enhanced Network Location Controller
/// Uses ONLY device network provider (WiFi/Cellular triangulation)
class NetworkLocationController extends GetxController {
  final LocationServiceV2 _locationService = LocationServiceV2();
  final NetworkLocationService _networkLocationService = NetworkLocationService();

  // Observables
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final Rx<Map<String, dynamic>?> _networkLocation = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isTracking = false.obs;
  final Rx<LocationPermission> _permissionStatus = LocationPermission.denied.obs;
  final RxDouble _currentAccuracy = 0.0.obs;
  final RxString _accuracyLevel = 'unknown'.obs;
  
  // Loading progress
  final RxString _loadingMessage = 'Mendapatkan lokasi...'.obs;
  final RxInt _loadingProgress = 0.obs;

  // Map controller
  MapController? _mapController;
  bool _isDisposed = false;

  // Map state
  final Rx<LatLng> _mapCenter = Rx<LatLng>(
    const LatLng(-7.9666, 112.6326), // Malang, East Java default
  );
  final RxDouble _mapZoom = 15.0.obs;

  // Stream subscription
  StreamSubscription<Position>? _positionSubscription;

  final RxList<LatLng> _trackingHistory = <LatLng>[].obs;
  final RxDouble _totalTrackingDistance = 0.0.obs;
  
  // Getters
  Position? get currentPosition => _currentPosition.value;
  Map<String, dynamic>? get networkLocation => _networkLocation.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isTracking => _isTracking.value;
  LocationPermission get permissionStatus => _permissionStatus.value;
  double get currentAccuracy => _currentAccuracy.value;
  String get accuracyLevel => _accuracyLevel.value;
  String get loadingMessage => _loadingMessage.value;
  int get loadingProgress => _loadingProgress.value;
  List<LatLng> get trackingHistory => _trackingHistory.value;
  double get totalTrackingDistance => _totalTrackingDistance.value;

  MapController get mapController {
    if (_mapController == null || _isDisposed) {
      try {
        _mapController?.dispose();
      } catch (e) {
        // Ignore dispose errors
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
      // Ignore
    }
    
    _mapController = MapController();
    
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] Initializing...');
      print('═══════════════════════════════════════════════════════════');
    }
    
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

  /// Initialize location on startup
  Future<void> _initializeLocation() async {
    if (kDebugMode) {
      print('🌐 [NETWORK CONTROLLER] Starting initialization...');
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Check and request permission
      _permissionStatus.value = await _locationService.checkPermission();

      if (_permissionStatus.value == LocationPermission.denied ||
          _permissionStatus.value == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('🌐 [NETWORK CONTROLLER] Permission needed, requesting...');
        }
        // Just set flag that permission is needed
        _permissionStatus.value = LocationPermission.denied;
      }

      _isLoading.value = false;
      
      if (kDebugMode) {
        print('✅ [NETWORK CONTROLLER] Initialization complete - ready for on-demand access');
      }

    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Initialization error: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Get current network location with FORCE REFRESH
  /// OPTIMIZED: Removed artificial delays for faster response
  Future<void> getCurrentNetworkLocation() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] getCurrentNetworkLocation() called');
      print('🌐 [NETWORK CONTROLLER] Will FORCE REFRESH from device');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      _loadingProgress.value = 10;
      _loadingMessage.value = 'Menghubungi penyedia lokasi jaringan...';

      // CRITICAL: Force refresh to get CURRENT location, not cached
      // This is the main bottleneck (10-30 seconds for network provider)
      final location = await _networkLocationService.getLocationFromNetwork(
        forceRefresh: true, // Always force refresh for accurate data
      );

      _loadingProgress.value = 90;
      _loadingMessage.value = 'Memproses data lokasi...';

      if (location != null) {
        _networkLocation.value = location;
        
        // Update accuracy metrics
        final acc = location['accuracy'] as double?;
        if (acc != null) {
          _currentAccuracy.value = acc;
          _accuracyLevel.value = NetworkLocationService.getAccuracyLevel(acc);
        }

        // Update map position
        _updateMapPosition(
          location['latitude'] as double,
          location['longitude'] as double,
        );

        _errorMessage.value = '';
        _loadingProgress.value = 100;
        _loadingMessage.value = 'Lokasi berhasil ditemukan!';

        if (kDebugMode) {
          print('✅ [NETWORK CONTROLLER] Network location received');
          print('📍 City: ${location['city']}');
          print('📍 Region: ${location['region']}');
          print('📍 Coordinates: [${location['latitude']}, ${location['longitude']}]');
          print('📍 Accuracy: ${location['accuracy']}m');
          print('📍 Source: ${location['source']}');
          print('📍 Connectivity: ${location['connectivity']}');
        }
      } else {
        throw Exception('Gagal mendapatkan lokasi jaringan: data lokasi kosong');
      }

      _isLoading.value = false;

    } on PermissionDeniedException catch (e) {
      _errorMessage.value = 'Izin lokasi ditolak. Silakan aktifkan izin lokasi.';
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Permission denied: $e');
      }
      
    } on TimeoutException catch (e) {
      _errorMessage.value = 'Waktu tunggu habis. Pastikan WiFi atau data seluler aktif dan coba lagi.';
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Timeout: $e');
      }
      
    } catch (e, stackTrace) {
      _errorMessage.value = 'Gagal mendapatkan lokasi: ${e.toString()}';
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Error: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Request location permission
  Future<void> requestPermission() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      if (kDebugMode) {
        print('🌐 [NETWORK CONTROLLER] Requesting permission...');
      }

      bool granted = await _locationService.requestPermission(
        requireGps: false, // Network provider only, no GPS needed
      );
      
      _permissionStatus.value = await _locationService.checkPermission();

      if (!granted) {
        final status = await _locationService.checkPermission();
        if (status == LocationPermission.deniedForever) {
          throw PermissionDeniedException(
            'Location permission permanently denied. Please enable in settings.',
          );
        } else {
          throw PermissionDeniedException(
            'Location permission denied. Please allow location access.',
          );
        }
      } else {
        _errorMessage.value = '';
        
        if (kDebugMode) {
          print('✅ [NETWORK CONTROLLER] Permission granted');
        }
        
        await getCurrentNetworkLocation();
      }

      _isLoading.value = false;

    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Permission request error: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Backward compatibility method
  Future<void> getCurrentPosition() async {
    await getCurrentNetworkLocation();
  }

  /// Get last known position (cached)
  Future<void> getLastKnownPosition() async {
    try {
      Position? position = await _locationService.getLastKnownPosition();

      if (position != null) {
        _currentPosition.value = position;
        _updateMapPosition(position.latitude, position.longitude);
        
        if (kDebugMode) {
          print('ℹ️ [NETWORK CONTROLLER] Using last known position');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last known position: $e');
      }
    }
  }

  /// Start live tracking using network provider
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
      _trackingHistory.clear();
      _totalTrackingDistance.value = 0.0;

      // Get position stream using network provider
      Stream<Position>? positionStream = _locationService.getPositionStream(
        useGps: false, // Network provider only
        distanceFilter: 10, // Update every 10 meters
      );

      if (positionStream != null) {
        _positionSubscription?.cancel();
        _positionSubscription = positionStream.listen(
          (Position position) {
            _currentPosition.value = position;
            _updateMapPosition(position.latitude, position.longitude);
            
            final newPoint = LatLng(position.latitude, position.longitude);
            if (_trackingHistory.isNotEmpty) {
              final lastPoint = _trackingHistory.last;
              final distance = _calculateDistance(lastPoint, newPoint);
              _totalTrackingDistance.value += distance;
            }
            _trackingHistory.add(newPoint);
            
            if (kDebugMode) {
              print('📍 [NETWORK CONTROLLER] 🔴 LIVE TRACKING UPDATE');
              print('📍 [NETWORK CONTROLLER] Position: [${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}]');
              print('📍 [NETWORK CONTROLLER] Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
              print('📍 [NETWORK CONTROLLER] Total Distance: ${_totalTrackingDistance.value.toStringAsFixed(3)}km');
              print('📍 [NETWORK CONTROLLER] History Points: ${_trackingHistory.length}');
            }
          },
          onError: (error) {
            _errorMessage.value = error.toString();
            if (kDebugMode) {
              print('❌ [NETWORK CONTROLLER] Stream error: $error');
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
        print('❌ [NETWORK CONTROLLER] Tracking error: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Earth's radius in km
    final lat1 = point1.latitude * 3.14159265359 / 180;
    final lat2 = point2.latitude * 3.14159265359 / 180;
    final dLat = (point2.latitude - point1.latitude) * 3.14159265359 / 180;
    final dLng = (point2.longitude - point1.longitude) * 3.14159265359 / 180;
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }

  /// Stop tracking
  void _stopTracking() {
    _isTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationService.stopPositionStream();
    
    if (kDebugMode) {
      print('🛑 [NETWORK CONTROLLER] Tracking stopped');
      print('📊 [NETWORK CONTROLLER] Final Stats:');
      print('   - Total distance: ${_totalTrackingDistance.value.toStringAsFixed(3)} km');
      print('   - Total points: ${_trackingHistory.length}');
    }
  }

  void stopTracking() {
    _stopTracking();
  }

  /// Update map position
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

  bool _canUseMapController() {
    return !_isDisposed && _mapController != null;
  }

  /// Update map center and zoom
  void updateMapCenter(LatLng center, double zoom) {
    if (_isDisposed) return;
    _mapCenter.value = center;
    _mapZoom.value = zoom;
  }

  /// Set zoom level
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

  /// Move map to current position
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

  /// Refresh position with force clear cache
  Future<void> refreshPosition() async {
    if (kDebugMode) {
      print('🔄 [NETWORK CONTROLLER] Manual refresh requested');
    }
    
    _networkLocationService.clearCache();
    await getCurrentNetworkLocation();
  }

  /// Reset map controller
  void resetMapController() {
    try {
      _mapController?.dispose();
    } catch (e) {
      // Ignore
    }
    _mapController = MapController();
    _isDisposed = false;
  }

  /// Toggle tracking on/off
  Future<void> toggleTracking() async {
    if (_isTracking.value) {
      stopTracking();
    } else {
      await startTracking();
    }
  }

  /// Get error action based on error type
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

  // Booking integration getters
  String? get selectedAddressForBooking {
    return _networkLocation.value?['address'] ?? 
           _networkLocation.value?['city'];
  }

  double? get selectedLatitudeForBooking => latitude;
  double? get selectedLongitudeForBooking => longitude;
}
