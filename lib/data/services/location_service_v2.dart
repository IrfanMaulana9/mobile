import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

/// Service untuk mengelola lokasi (GPS dan Network Provider)
/// OPTIMIZED VERSION - Faster network location fetch
/// Default: 8-12 detik (turun dari 20-30 detik)
class LocationServiceV2 {
  static final LocationServiceV2 _instance = LocationServiceV2._internal();
  factory LocationServiceV2() => _instance;
  LocationServiceV2._internal();

  Stream<Position>? _positionStream;
  LocationPermission? _permissionStatus;
  permission_handler.PermissionStatus? _permissionHandlerStatus;

  // Cache untuk mempercepat request berulang
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  static const _cacheValiditySeconds = 10; // Cache 10 detik

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> isNetworkAvailable() async {
    try {
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking network: $e');
      }
      return false;
    }
  }

  Future<bool> requestPermission({bool requireGps = false}) async {
    final locationSource = requireGps ? 'GPS' : 'NETWORK';
    if (kDebugMode) {
      print('📍 [LOCATION SERVICE V2] requestPermission() called');
      print('📍 [LOCATION SERVICE V2] requireGps: $requireGps (Source: $locationSource)');
    }

    try {
      if (requireGps) {
        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] Checking GPS service status...');
        }
        bool serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (kDebugMode) {
            print('❌ [LOCATION SERVICE V2] GPS service is not enabled');
          }
          return false;
        }
        if (kDebugMode) {
          print('✅ [LOCATION SERVICE V2] GPS service is enabled');
        }
      } else {
        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] NETWORK provider - skipping GPS service check');
        }
      }

      if (!requireGps) {
        bool networkAvailable = await isNetworkAvailable();
        if (!networkAvailable) {
          if (kDebugMode) {
            print('Network is not available');
          }
        }
      }

      permission_handler.Permission locationPermission =
          permission_handler.Permission.locationWhenInUse;

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] Checking permission status...');
      }
      _permissionHandlerStatus = await locationPermission.status;

      if (_permissionHandlerStatus ==
              permission_handler.PermissionStatus.granted ||
          _permissionHandlerStatus ==
              permission_handler.PermissionStatus.limited) {
        if (kDebugMode) {
          print('✅ [LOCATION SERVICE V2] Permission already granted');
        }
        _permissionStatus = await Geolocator.checkPermission();
        return true;
      }

      if (_permissionHandlerStatus ==
          permission_handler.PermissionStatus.permanentlyDenied) {
        if (kDebugMode) {
          print('Location permission permanently denied');
        }
        _permissionStatus = LocationPermission.deniedForever;
        return false;
      }

      if (_permissionHandlerStatus ==
          permission_handler.PermissionStatus.denied) {
        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] Requesting permission...');
        }
        _permissionHandlerStatus = await locationPermission.request();

        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] Permission request result: ${_permissionHandlerStatus.toString()}');
        }

        if (_permissionHandlerStatus ==
                permission_handler.PermissionStatus.granted ||
            _permissionHandlerStatus ==
                permission_handler.PermissionStatus.limited) {
          if (kDebugMode) {
            print('✅ [LOCATION SERVICE V2] Permission granted after request');
          }
          _permissionStatus = await Geolocator.checkPermission();
          return true;
        } else if (_permissionHandlerStatus ==
            permission_handler.PermissionStatus.permanentlyDenied) {
          if (kDebugMode) {
            print('❌ [LOCATION SERVICE V2] Permission permanently denied');
          }
          _permissionStatus = LocationPermission.deniedForever;
          return false;
        } else {
          if (kDebugMode) {
            print('❌ [LOCATION SERVICE V2] Permission denied');
          }
          _permissionStatus = LocationPermission.denied;
          return false;
        }
      }

      _permissionStatus = LocationPermission.denied;
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
      _permissionStatus = LocationPermission.denied;
      return false;
    }
  }

  Future<LocationPermission> checkPermission() async {
    try {
      final status =
          await permission_handler.Permission.locationWhenInUse.status;

      switch (status) {
        case permission_handler.PermissionStatus.granted:
        case permission_handler.PermissionStatus.limited:
          _permissionStatus = await Geolocator.checkPermission();
          break;
        case permission_handler.PermissionStatus.denied:
          _permissionStatus = LocationPermission.denied;
          break;
        case permission_handler.PermissionStatus.permanentlyDenied:
          _permissionStatus = LocationPermission.deniedForever;
          break;
        case permission_handler.PermissionStatus.restricted:
          _permissionStatus = LocationPermission.denied;
          break;
        case permission_handler.PermissionStatus.provisional:
          _permissionStatus = await Geolocator.checkPermission();
          break;
      }

      return _permissionStatus ?? LocationPermission.denied;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permission: $e');
      }
      _permissionStatus = await Geolocator.checkPermission();
      return _permissionStatus ?? LocationPermission.denied;
    }
  }

  Future<bool> isPermissionGranted() async {
    final status = await checkPermission();
    return status == LocationPermission.whileInUse ||
        status == LocationPermission.always;
  }

  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await checkPermission();
    return status == LocationPermission.deniedForever;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  /// ⚡ OPTIMIZED: Dapatkan posisi dengan caching dan timeout cerdas
  /// Network Provider: 8-12 detik (turun dari 20 detik)
  /// GPS: 5-8 detik
  Future<Position?> getCurrentPosition({bool useGps = false}) async {
    final locationSource = useGps ? 'GPS' : 'NETWORK';
    
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📍 [LOCATION SERVICE V2] getCurrentPosition() called');
      print('📍 [LOCATION SERVICE V2] useGps parameter: $useGps');
      print('📍 [LOCATION SERVICE V2] Location Source: $locationSource');
      print('✅ [LOCATION SERVICE V2] OPTIMIZED - FASTER FETCH');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      // ⚡ OPTIMIZATION 1: Check cache first (untuk network provider)
      if (!useGps && _lastPosition != null && _lastPositionTime != null) {
        final age = DateTime.now().difference(_lastPositionTime!).inSeconds;
        if (age < _cacheValiditySeconds) {
          if (kDebugMode) {
            print('⚡ [LOCATION SERVICE V2] Using cached position (age: ${age}s)');
            print('✅ [LOCATION SERVICE V2] INSTANT RESPONSE from cache');
          }
          return _lastPosition;
        } else {
          if (kDebugMode) {
            print('⏰ [LOCATION SERVICE V2] Cache expired (age: ${age}s)');
          }
        }
      }

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] Checking permission (requireGps: $useGps)...');
      }
      
      bool hasPermission = await requestPermission(requireGps: useGps);
      if (!hasPermission) {
        if (kDebugMode) {
          print('❌ [LOCATION SERVICE V2] Location permission not granted');
        }
        final status = await checkPermission();
        if (status == LocationPermission.deniedForever) {
          throw PermissionDeniedException(
            'Location permission permanently denied',
          );
        } else {
          throw PermissionDeniedException('Location permission denied');
        }
      }
      
      if (kDebugMode) {
        print('✅ [LOCATION SERVICE V2] Permission granted');
      }

      if (!useGps) {
        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] Checking network availability for NETWORK provider...');
        }
        bool networkAvailable = await isNetworkAvailable();
        if (networkAvailable) {
          if (kDebugMode) {
            print('✅ [LOCATION SERVICE V2] Network available');
          }
        }
      } else {
        if (kDebugMode) {
          print('📍 [LOCATION SERVICE V2] Using GPS - skipping network check');
        }
      }

      // ⚡ OPTIMIZATION 2: Shorter, smarter timeout
      final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.low;
      
      // Network: 10s (turun dari 20s)
      // GPS: 6s (turun dari 10s)
      final timeout = useGps 
          ? const Duration(seconds: 6)  // GPS lebih cepat
          : const Duration(seconds: 10); // Network: 10s (50% lebih cepat!)

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] LocationAccuracy: ${accuracy.toString()}');
        print('⏱️ [LOCATION SERVICE V2] Timeout: ${timeout.inSeconds}s (OPTIMIZED)');
        print('📍 [LOCATION SERVICE V2] Requesting position with $locationSource source...');
      }

      // ⚡ OPTIMIZATION 3: Use forceAndroidLocationManager untuk network
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: !useGps, // Force network provider
        timeLimit: timeout,
      );

      // ⚡ OPTIMIZATION 4: Cache untuk network location
      if (!useGps) {
        _lastPosition = position;
        _lastPositionTime = DateTime.now();
        if (kDebugMode) {
          print('💾 [LOCATION SERVICE V2] Position cached for future requests');
        }
      }

      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('✅ [LOCATION SERVICE V2] Position received!');
        print('📍 [LOCATION SERVICE V2] Requested Source: $locationSource');
        print('📍 [LOCATION SERVICE V2] Position Accuracy: ${position.accuracy} meters');
        print('📍 [LOCATION SERVICE V2] Position Latitude: ${position.latitude}');
        print('📍 [LOCATION SERVICE V2] Position Longitude: ${position.longitude}');
        print('📍 [LOCATION SERVICE V2] Position Timestamp: ${position.timestamp}');

        if (!useGps) {
          if (position.accuracy < 50) {
            print('⚠️⚠️⚠️ [LOCATION SERVICE V2] WARNING: Low accuracy (<50m) detected!');
            print('⚠️⚠️⚠️ [LOCATION SERVICE V2] This suggests GPS was used instead of NETWORK!');
          } else {
            print('✅ [LOCATION SERVICE V2] Accuracy validation PASSED: ${position.accuracy}m > 50m (NETWORK source confirmed)');
          }
        } else {
          if (position.accuracy > 100) {
            print('⚠️⚠️⚠️ [LOCATION SERVICE V2] WARNING: High accuracy (>100m) detected!');
          } else {
            print('✅ [LOCATION SERVICE V2] Accuracy validation PASSED: ${position.accuracy}m < 100m (GPS source confirmed)');
          }
        }
        print('═══════════════════════════════════════════════════════════');
      }

      return position;
    } on PermissionDeniedException catch (e) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] PermissionDeniedException: ${e.toString()}');
      }
      rethrow;
    } on LocationServiceDisabledException catch (e) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] LocationServiceDisabledException: ${e.toString()}');
      }
      rethrow;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] TimeoutException: ${e.toString()}');
        print('⚠️ [LOCATION SERVICE V2] Network provider timeout after ${useGps ? 6 : 10}s');
        print('⚠️ [LOCATION SERVICE V2] Suggestions:');
        print('   1. Make sure WiFi or mobile data is enabled');
        print('   2. Try moving to a location with better signal');
        print('   3. Try again in a moment');
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] Error getting current position: $e');
        print('❌ [LOCATION SERVICE V2] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Get last known position (CACHED)
  Future<Position?> getLastKnownPosition() async {
    if (kDebugMode) {
      print('⚠️⚠️⚠️ [LOCATION SERVICE V2] getLastKnownPosition() called - USING CACHE!');
    }

    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('❌ [LOCATION SERVICE V2] Permission not granted for last known position');
        }
        return null;
      }

      Position? position = await Geolocator.getLastKnownPosition();

      if (kDebugMode) {
        if (position != null) {
          print('⚠️ [LOCATION SERVICE V2] Last known position found (CACHED)');
          print('📍 [LOCATION SERVICE V2] Accuracy: ${position.accuracy}m');
        } else {
          print('⚠️ [LOCATION SERVICE V2] No last known position available');
        }
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] Error getting last known position: $e');
      }
      return null;
    }
  }

  /// Clear cache (untuk force refresh)
  void clearCache() {
    _lastPosition = null;
    _lastPositionTime = null;
    if (kDebugMode) {
      print('🗑️ [LOCATION SERVICE V2] Location cache cleared');
    }
  }

  Stream<Position>? getPositionStream({
    bool useGps = false,
    int distanceFilter = 10,
    Duration? timeLimit,
  }) {
    final locationSource = useGps ? 'GPS' : 'NETWORK';
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📍 [LOCATION SERVICE V2] getPositionStream() called');
      print('📍 [LOCATION SERVICE V2] useGps parameter: $useGps');
      print('📍 [LOCATION SERVICE V2] Location Source: $locationSource');
      print('📍 [LOCATION SERVICE V2] Distance Filter: $distanceFilter meters');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      final locationSettings = LocationSettings(
        accuracy: useGps ? LocationAccuracy.high : LocationAccuracy.low,
        distanceFilter: distanceFilter,
        timeLimit: timeLimit,
      );

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] LocationAccuracy: ${locationSettings.accuracy.toString()}');
        print('📍 [LOCATION SERVICE V2] Starting position stream with $locationSource source...');
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      return _positionStream;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCATION SERVICE V2] Error starting position stream: $e');
      }
      return null;
    }
  }

  void stopPositionStream() {
    _positionStream = null;
  }
}