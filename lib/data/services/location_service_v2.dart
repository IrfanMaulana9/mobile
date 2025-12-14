import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

/// Service untuk mengelola lokasi (GPS dan Network Provider)
/// Menggunakan Geolocator dengan best practices
/// Default menggunakan Network Provider saja (tanpa GPS)
/// Fixed: Extended timeout untuk network provider yang lebih lambat
class LocationServiceV2 {
  static final LocationServiceV2 _instance = LocationServiceV2._internal();
  factory LocationServiceV2() => _instance;
  LocationServiceV2._internal();

  /// Stream untuk mendapatkan posisi real-time
  Stream<Position>? _positionStream;

  /// Status permission saat ini
  LocationPermission? _permissionStatus;

  /// Permission status dari permission_handler
  permission_handler.PermissionStatus? _permissionHandlerStatus;

  /// Cek apakah GPS service enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Cek status network connection
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

  /// Request permission untuk akses lokasi
  /// [requireGps]: true jika memerlukan GPS aktif, false untuk network provider saja
  Future<bool> requestPermission({bool requireGps = false}) async {
    final locationSource = requireGps ? 'GPS' : 'NETWORK';
    if (kDebugMode) {
      print('📍 [LOCATION SERVICE V2] requestPermission() called');
      print('📍 [LOCATION SERVICE V2] requireGps: $requireGps (Source: $locationSource)');
    }

    try {
      // Jika memerlukan GPS, cek apakah service enabled
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

      // Untuk network provider, cek network availability
      if (!requireGps) {
        bool networkAvailable = await isNetworkAvailable();
        if (!networkAvailable) {
          if (kDebugMode) {
            print('Network is not available');
          }
        }
      }

      // Cek permission menggunakan permission_handler
      permission_handler.Permission locationPermission =
          permission_handler.Permission.locationWhenInUse;

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] Checking permission status...');
      }
      _permissionHandlerStatus = await locationPermission.status;

      // Jika permission sudah granted
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

      // Jika permission permanently denied
      if (_permissionHandlerStatus ==
          permission_handler.PermissionStatus.permanentlyDenied) {
        if (kDebugMode) {
          print('Location permission permanently denied');
        }
        _permissionStatus = LocationPermission.deniedForever;
        return false;
      }

      // Request permission jika belum granted
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

  /// Cek permission status
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

  /// Cek apakah permission sudah granted
  Future<bool> isPermissionGranted() async {
    final status = await checkPermission();
    return status == LocationPermission.whileInUse ||
        status == LocationPermission.always;
  }

  /// Cek apakah permission permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await checkPermission();
    return status == LocationPermission.deniedForever;
  }

  /// Buka settings untuk enable permission
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Buka app settings
  Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  /// Dapatkan posisi saat ini (one-time) - FRESH DATA, NO CACHE
  /// [useGps]: true untuk GPS (high accuracy), false untuk network provider saja
  /// Default: false (network provider saja)
  /// FIXED: Extended timeout untuk network provider yang lebih lambat
  Future<Position?> getCurrentPosition({bool useGps = false}) async {
    final locationSource = useGps ? 'GPS' : 'NETWORK';
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📍 [LOCATION SERVICE V2] getCurrentPosition() called');
      print('📍 [LOCATION SERVICE V2] useGps parameter: $useGps');
      print('📍 [LOCATION SERVICE V2] Location Source: $locationSource');
      print('✅ [LOCATION SERVICE V2] FRESH FETCH - NO CACHE will be used');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
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

      // Untuk network provider, cek network availability
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

      // Pilih akurasi berdasarkan GPS toggle
      // LocationAccuracy.low = network provider saja (tanpa GPS)
      // LocationAccuracy.high = GPS dengan akurasi tinggi
      final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.low;

      // OPTIMIZED: Smart timeout based on source
      // Network provider: 15-20 seconds (reduced from 30)
      // GPS: 10 seconds
      final timeout = useGps 
          ? const Duration(seconds: 10) 
          : const Duration(seconds: 20); // Optimized from 30 to 20

      if (kDebugMode) {
        print('📍 [LOCATION SERVICE V2] LocationAccuracy: ${accuracy.toString()}');
        print('📍 [LOCATION SERVICE V2] Timeout: ${timeout.inSeconds} seconds');
        print('📍 [LOCATION SERVICE V2] Requesting position with $locationSource source...');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: !useGps, // Force network provider jika useGps = false
        timeLimit: timeout, // Optimized timeout
      );

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
        print('⚠️ [LOCATION SERVICE V2] Network provider might be taking longer than expected');
        print('⚠️ [LOCATION SERVICE V2] Suggestions:');
        print('   1. Make sure WiFi or mobile data is enabled');
        print('   2. Try moving to a location with better signal');
        print('   3. Wait a moment and try again');
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

  /// Dapatkan posisi terakhir yang diketahui (CACHED)
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

  /// Mulai listening posisi real-time
  /// [useGps]: true untuk GPS (high accuracy), false untuk network provider saja
  /// Default: false (network provider saja)
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
      // LocationSettings constructor accepts: accuracy, distanceFilter, timeLimit
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

  /// Stop position stream
  void stopPositionStream() {
    _positionStream = null;
  }
}