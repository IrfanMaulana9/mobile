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
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestGPSPermissionsAndInitialize() async {
    try {
      controller.isLoading.value = true;
      await controller.initializeGPS();
      
      if (controller.isGPSInitialized.value) {
        Get.snackbar(
          'Sukses',
          'GPS siap digunakan',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 2),
        );
      } else {
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

  Color _getAccuracyColor(String level) {
    final accuracy = double.tryParse(level) ?? 0;
    
    if (accuracy <= 10) {
      return Colors.green;
    } else if (accuracy <= 50) {
      return Colors.lightGreen;
    } else if (accuracy <= 100) {
      return Colors.blue;
    } else if (accuracy <= 500) {
      return Colors.orange;
    } else {
      return Colors.red;
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
            icon: Icon(controller.isTracking.value ? Icons.pause_circle : Icons.play_circle),
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
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Aktifkan GPS'),
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _requestGPSPermissionsAndInitialize,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Aktifkan GPS'),
                          ),
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
                        MarkerLayer(
                          markers: [
                            // Current position marker - red
                            Marker(
                              point: currentLocation,
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 48,
                              ),
                            ),
                            if (controller.isTracking.value && controller.locationHistory.length > 1)
                              ...List.generate(
                                  controller.locationHistory.length - 1, (index) {
                                final entry = controller.locationHistory[index];
                                return Marker(
                                  point: LatLng(
                                      entry.latitude, entry.longitude),
                                  width: 8,
                                  height: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary.withAlpha(200),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                        if (controller.isTracking.value && controller.locationHistory.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: controller.locationHistory
                                    .map((e) => LatLng(e.latitude, e.longitude))
                                    .toList(),
                                strokeWidth: 3,
                                color: cs.primary.withAlpha(180),
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
            // Info panel - Redesigned to match Network Location page style
            Expanded(
              flex: 1,
              child: Container(
                color: cs.surface,
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final position = controller.currentPosition.value;
                  final accuracyStr = controller.accuracy.value;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'GPS (Sangat Akurat)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (accuracyStr.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getAccuracyColor(accuracyStr).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getAccuracyColor(accuracyStr).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  controller.getAccuracyDescription(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getAccuracyColor(accuracyStr),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (controller.isTracking.value)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Live Tracking',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (position != null) ...[
                                _buildInfoRow(cs, 'Latitude', position.latitude.toStringAsFixed(6)),
                                _buildDivider(cs),
                                _buildInfoRow(cs, 'Longitude', position.longitude.toStringAsFixed(6)),
                                _buildDivider(cs),
                                _buildInfoRow(cs, 'Akurasi', '${controller.accuracy.value} m'),
                                _buildDivider(cs),
                                _buildInfoRow(cs, 'Altitude', '${position.altitude.toStringAsFixed(2)} m'),
                                _buildDivider(cs),
                                _buildInfoRow(cs, 'Waktu', controller.currentAddress.value),
                              ] else
                                Text(
                                  'Mendapatkan lokasi...',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        if (controller.isTracking.value) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  cs,
                                  'Jarak Tempuh',
                                  '${controller.totalDistance.value.toStringAsFixed(3)} km',
                                ),
                                _buildDivider(cs),
                                _buildInfoRow(
                                  cs,
                                  'Titik Rekam',
                                  controller.locationHistory.length.toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(
      height: 12,
      color: cs.outline.withOpacity(0.1),
      thickness: 1,
    );
  }
}
