import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/gps_controller.dart';
import '../controllers/network_location_controller.dart';
import '../services/network_location_service.dart';

class NetworkLocationPage extends StatefulWidget {
  static const String routeName = '/network-location';

  const NetworkLocationPage({super.key});

  @override
  State<NetworkLocationPage> createState() => _NetworkLocationPageState();
}

class _NetworkLocationPageState extends State<NetworkLocationPage> {
  final networkController = Get.put(NetworkLocationController());
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

  void _centerMap() {
    final location = networkController.networkLocation;
    if (location != null) {
      _mapController.move(
        LatLng(location['latitude'], location['longitude']),
        17.0,
      );
    }
  }

  Color _getSourceColor(Map<String, dynamic>? location) {
    if (location == null) return Colors.grey;
    
    final connectivity = location['connectivity'] as String?;
    
    if (connectivity?.contains('WiFi') ?? false) {
      return Colors.green;
    } else if (connectivity?.contains('Cellular') ?? false) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  Color _getAccuracyColor(String level) {
    switch (level) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.blue;
      case 'poor':
        return Colors.orange;
      case 'very_poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Location Tracker'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              networkController.isTracking 
                ? Icons.pause_circle 
                : Icons.play_circle,
            ),
            onPressed: networkController.isTracking
              ? networkController.stopTracking
              : networkController.startTracking,
          )),
        ],
      ),
      body: Obx(() {
        final location = networkController.networkLocation;
        final isLoading = networkController.isLoading;

        if (isLoading && location == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
                const SizedBox(height: 16),
                const Text('Mendapatkan lokasi dengan akurasi tinggi...'),
              ],
            ),
          );
        }

        if (location == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('Lokasi tidak tersedia'),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan WiFi atau data seluler aktif',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: networkController.requestPermission,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Aktifkan Lokasi'),
                ),
              ],
            ),
          );
        }

        final currentLocation = LatLng(location['latitude'], location['longitude']);
        final accuracy = NetworkLocationService.getAccuracy(location);
        final sourceInfo = NetworkLocationService.getLocationSourceInfo(location);
        final sourceAccuracy = NetworkLocationService.getSourceAccuracyDescription(location);
        final sourceColor = _getSourceColor(location);

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
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
                          Marker(
                            point: currentLocation,
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.location_on,
                              color: sourceColor,
                              size: 48,
                            ),
                          ),
                          if (networkController.isTracking && 
                              networkController.trackingHistory.isNotEmpty)
                            ...List.generate(
                              networkController.trackingHistory.length,
                              (index) {
                                final point = networkController.trackingHistory[index];
                                return Marker(
                                  point: point,
                                  width: 6,
                                  height: 6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary.withAlpha(180),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (networkController.isTracking && 
                          networkController.trackingHistory.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: networkController.trackingHistory,
                              strokeWidth: 2,
                              color: cs.primary.withAlpha(150),
                            ),
                          ],
                        ),
                    ],
                  ),
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
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: cs.surface,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Network Provider',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (accuracy != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getAccuracyColor(networkController.accuracyLevel).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getAccuracyColor(networkController.accuracyLevel).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                NetworkLocationService.getAccuracyDescription(accuracy),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getAccuracyColor(networkController.accuracyLevel),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (networkController.isTracking)
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
                            _buildInfoRow(cs, 'Latitude', location['latitude'].toStringAsFixed(6)),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Longitude', location['longitude'].toStringAsFixed(6)),
                            _buildDivider(cs),
                            _buildInfoRow(
                              cs,
                              'Akurasi',
                              accuracy != null ? '${accuracy.toStringAsFixed(0)} m' : 'Unknown',
                            ),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Tipe Lokasi', 'Network Provider Device'),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Kota', location['city'] ?? 'Unknown'),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Region', location['region'] ?? 'Unknown'),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Alamat', location['address'] ?? 'Unknown'),
                            _buildDivider(cs),
                            _buildInfoRow(cs, 'Konektivitas', location['connectivity'] ?? 'Unknown'),
                          ],
                        ),
                      ),
                      if (networkController.isTracking) ...[
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
                                '${networkController.totalTrackingDistance.toStringAsFixed(3)} km',
                              ),
                              _buildDivider(cs),
                              _buildInfoRow(
                                cs,
                                'Titik Rekam',
                                networkController.trackingHistory.length.toString(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : networkController.refreshPosition,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Perbarui Lokasi'),
                        ),
                      ),
                    ],
                  ),
                ),
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
