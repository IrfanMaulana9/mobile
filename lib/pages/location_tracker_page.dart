import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/gps_controller.dart';
import '../services/location_mode_service.dart';
import '../widgets/location_mode_selector.dart';

class LocationTrackerPage extends StatefulWidget {
  static const String routeName = '/location-tracker';

  const LocationTrackerPage({super.key});

  @override
  State<LocationTrackerPage> createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  late final GPSController _gpsController;
  final locationModeService = LocationModeService();
  
  late MapController _mapController;
  String _currentMode = 'hybrid';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    try {
      _gpsController = Get.find<GPSController>();
    } catch (e) {
      // If controller not found, show error and return early
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'GPSController tidak ditemukan. Silakan restart aplikasi.',
          backgroundColor: Colors.red.shade100,
        );
      });
      // Create a dummy controller to prevent null reference
      _gpsController = GPSController();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getLocationByMode(String mode) async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await locationModeService.getCurrentLocation(mode);
      
      if (location != null) {
        // Update GPS controller
        final position = await _gpsController.gpsService.getCurrentLocation();
        if (position != null) {
          _gpsController.currentPosition.value = position;
          _gpsController.currentAddress.value = location.address;
          _gpsController.locationType.value = location.locationType;
          
          // Center map
          _mapController.move(
            LatLng(location.latitude, location.longitude),
            17.0,
          );
          
          Get.snackbar(
            'Sukses',
            'Lokasi dari ${LocationModeService.getModeDescription(mode)}',
            backgroundColor: Colors.green.shade100,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Gagal mendapatkan lokasi dari ${LocationModeService.getModeDescription(mode)}',
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e', backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _centerMap() {
    final position = _gpsController.currentPosition.value;
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        17.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker Lokasi'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              _gpsController.isTracking.value ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              if (_gpsController.isTracking.value) {
                _gpsController.stopLiveTracking();
              } else {
                _gpsController.startLiveTracking();
              }
            },
          )),
        ],
      ),
      body: Column(
        children: [
          // Location mode selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: LocationModeSelector(
              selectedMode: _currentMode,
              onModeChanged: (mode) {
                setState(() => _currentMode = mode);
              },
            ),
          ),

          // Map
          Expanded(
            flex: 2,
            child: Obx(() {
              final position = _gpsController.currentPosition.value;
              
              if (position == null) {
                return Container(
                  color: cs.surface,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text('Lokasi tidak tersedia'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : () => _getLocationByMode(_currentMode),
                          icon: const Icon(Icons.location_searching),
                          label: const Text('Dapatkan Lokasi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final currentLocation = LatLng(position.latitude, position.longitude);

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentLocation,
                      initialZoom: 17.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.libbooking.app',
                        maxZoom: 18,
                        minZoom: 10,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentLocation,
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.location_on,
                              color: cs.error,
                              size: 48,
                            ),
                          ),
                          if (_gpsController.locationHistory.length > 1)
                            ...List.generate(
                              _gpsController.locationHistory.length,
                              (index) {
                                final entry = _gpsController.locationHistory[index];
                                return Marker(
                                  point: LatLng(entry.latitude, entry.longitude),
                                  width: 8,
                                  height: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (_gpsController.locationHistory.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _gpsController.locationHistory
                                  .map((e) => LatLng(e.latitude, e.longitude))
                                  .toList(),
                              strokeWidth: 3,
                              color: cs.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Floating action button for centering
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _centerMap,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              );
            }),
          ),

          // Info panel
          Expanded(
            flex: 1,
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final position = _gpsController.currentPosition.value;
                
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _gpsController.locationType.value == 'gps'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _gpsController.getLocationTypeDescription(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _gpsController.locationType.value == 'gps'
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (position != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _gpsController.getAccuracyDescription(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (position != null) ...[
                        _buildInfoRow(
                          cs,
                          'Koordinat:',
                          '${position.latitude.toStringAsFixed(6)}, '
                          '${position.longitude.toStringAsFixed(6)}',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          cs,
                          'Akurasi:',
                          '${_gpsController.accuracy.value} m',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          cs,
                          'Ketinggian:',
                          '${_gpsController.altitude.value.toStringAsFixed(2)} m',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          cs,
                          'Kecepatan:',
                          '${(_gpsController.speed.value * 3.6).toStringAsFixed(2)} km/h',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          cs,
                          'Lokasi:',
                          _gpsController.currentAddress.value,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingLocation
                                  ? null
                                  : () => _getLocationByMode(_currentMode),
                              icon: const Icon(Icons.location_searching),
                              label: const Text('Perbarui'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _gpsController.clearHistory,
                              icon: const Icon(Icons.clear),
                              label: const Text('Hapus'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme cs, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
