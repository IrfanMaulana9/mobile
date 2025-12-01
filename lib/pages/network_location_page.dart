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
      ),
      body: Obx(() {
        final location = networkController.networkLocation;
        final isLoading = networkController.isLoading;

        if (isLoading) {
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
                  onPressed: networkController.getCurrentNetworkLocation,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Dapatkan Lokasi'),
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
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Device Network Provider',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          if (accuracy != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getAccuracyColor(networkController.accuracyLevel).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                NetworkLocationService.getAccuracyDescription(accuracy),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getAccuracyColor(networkController.accuracyLevel),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(cs, 'Latitude:', location['latitude'].toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Longitude:', location['longitude'].toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Akurasi:',
                        accuracy != null ? '${accuracy.toStringAsFixed(0)} m' : 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Tipe Lokasi:', 'Network Provider Device'),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Kota:', location['city'] ?? 'Unknown'),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Region:', location['region'] ?? 'Unknown'),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Alamat:', location['address'] ?? 'Unknown'),
                      const SizedBox(height: 8),
                      _buildInfoRow(cs, 'Konektivitas:', location['connectivity'] ?? 'Unknown'),
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
