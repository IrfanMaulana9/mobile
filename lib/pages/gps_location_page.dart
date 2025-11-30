import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/gps_controller.dart';

class GPSLocationPage extends StatefulWidget {
  static const String routeName = '/gps-location';

  const GPSLocationPage({super.key});

  @override
  State<GPSLocationPage> createState() => _GPSLocationPageState();
}

class _GPSLocationPageState extends State<GPSLocationPage> {
  final controller = Get.put(GPSController());
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestGPSPermissionsAndInitialize();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestGPSPermissionsAndInitialize() async {
    try {
      controller.isLoading.value = true;
      final success = await controller.gpsService.initializeGPS();
      if (success) {
        await controller.getCurrentLocation();
        controller.isGPSInitialized.value = true;
        Get.snackbar(
          'Sukses',
          'GPS siap digunakan',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 2),
        );
      } else {
        controller.isGPSInitialized.value = false;
        Get.snackbar(
          'Error',
          'Gagal menginisialisasi GPS',
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: $e',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      controller.isLoading.value = false;
    }
  }

  void _centerMap() {
    final position = controller.currentPosition.value;
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
        title: const Text('GPS Location'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.isTracking.value ? Icons.pause : Icons.play_arrow),
            onPressed: controller.isGPSInitialized.value
                ? () {
                    if (controller.isTracking.value) {
                      controller.stopLiveTracking();
                    } else {
                      controller.startLiveTracking();
                    }
                  }
                : null,
          )),
        ],
      ),
      body: Obx(() {
        // Show loading state when initializing
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
                const SizedBox(height: 16),
                const Text('Menginisialisasi GPS...'),
              ],
            ),
          );
        }

        // Show error state if GPS initialization failed
        if (!controller.isGPSInitialized.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('GPS tidak tersedia'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _requestGPSPermissionsAndInitialize,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Map section
            Expanded(
              flex: 2,
              child: Obx(() {
                final position = controller.currentPosition.value;

                if (position == null) {
                  return Container(
                    color: cs.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off,
                              size: 64, color: cs.onSurfaceVariant),
                          const SizedBox(height: 16),
                          const Text('Lokasi tidak tersedia'),
                        ],
                      ),
                    ),
                  );
                }

                final currentLocation =
                    LatLng(position.latitude, position.longitude);

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
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.libbooking.app',
                          maxZoom: 18,
                          minZoom: 10,
                        ),
                        // Current position marker
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
                            // Show history trail
                            if (controller.locationHistory.length > 1)
                              ...List.generate(
                                  controller.locationHistory.length, (index) {
                                final entry = controller.locationHistory[index];
                                return Marker(
                                  point: LatLng(
                                      entry.latitude, entry.longitude),
                                  width: 8,
                                  height: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                        // Polyline for tracking history
                        if (controller.locationHistory.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: controller.locationHistory
                                    .map((e) => LatLng(e.latitude, e.longitude))
                                    .toList(),
                                strokeWidth: 3,
                                color: cs.primary,
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Floating map controls
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            onPressed: () => _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            ),
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            onPressed: () => _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            ),
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            onPressed: _centerMap,
                            child: const Icon(Icons.my_location),
                          ),
                        ],
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
                  final position = controller.currentPosition.value;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location type badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'GPS (Sangat Akurat)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.getAccuracyDescription(),
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
                        // Coordinates
                        if (position != null) ...[
                          _buildInfoRow(
                            cs,
                            'Latitude:',
                            position.latitude.toStringAsFixed(6),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            cs,
                            'Longitude:',
                            position.longitude.toStringAsFixed(6),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            cs,
                            'Akurasi:',
                            '${controller.accuracy.value} m',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            cs,
                            'Altitude:',
                            '${controller.altitude.value.toStringAsFixed(2)} m',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            cs,
                            'Waktu:',
                            controller.currentAddress.value,
                          ),
                        ] else
                          Text(
                            'Mendapatkan lokasi...',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _centerMap,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Pusatkan'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controller.clearHistory,
                                icon: const Icon(Icons.clear),
                                label: const Text('Hapus Riwayat'),
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
        );
      }),
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
