import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/gps_controller.dart';
import '../services/network_location_service.dart';
import '../services/wifi_location_service.dart';

class NetworkLocationPage extends StatefulWidget {
  static const String routeName = '/network-location';

  const NetworkLocationPage({super.key});

  @override
  State<NetworkLocationPage> createState() => _NetworkLocationPageState();
}

class _NetworkLocationPageState extends State<NetworkLocationPage> {
  final controller = Get.put(GPSController());
  final networkService = NetworkLocationService();
  final wifiService = WiFiLocationService();
  late MapController _mapController;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getNetworkLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getNetworkLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await networkService.getLocationFromNetwork();

      if (location != null) {
        controller.networkLocation.value = location;
        controller.currentAddress.value =
            '${location['city']}, ${location['region']}';
        controller.locationType.value = 'network';

        controller.currentPosition.value = null;

        _mapController.move(
          LatLng(location['latitude'], location['longitude']),
          17.0,
        );

        final sourceInfo = NetworkLocationService.getLocationSourceInfo(location);
        final accuracy = NetworkLocationService.getAccuracy(location);
        final accuracyText = accuracy != null
            ? WiFiLocationService.getAccuracyDescription(accuracy)
            : 'Unknown';

        Get.snackbar(
          'Sukses',
          'Lokasi diperoleh\nSumber: $sourceInfo\nAkurasi: $accuracyText',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Gagal mendapatkan lokasi dari Network Provider',
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
      setState(() => _isLoadingLocation = false);
    }
  }

  void _centerMap() {
    final networkLoc = controller.networkLocation.value;
    if (networkLoc != null) {
      _mapController.move(
        LatLng(networkLoc['latitude'], networkLoc['longitude']),
        17.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Location'),
        centerTitle: true,
      ),
      body: Obx(() {
        final networkLoc = controller.networkLocation.value;

        if (_isLoadingLocation) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
                const SizedBox(height: 16),
                const Text('Mendapatkan lokasi...'),
              ],
            ),
          );
        }

        if (networkLoc == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('Lokasi tidak tersedia'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getNetworkLocation,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Dapatkan Lokasi'),
                ),
              ],
            ),
          );
        }

        final currentLocation =
            LatLng(networkLoc['latitude'], networkLoc['longitude']);
        
        final isHighAccuracyWiFi =
            NetworkLocationService.isHighAccuracyWiFi(networkLoc);
        final isWiFiBased = NetworkLocationService.isWiFiBasedLocation(networkLoc);
        final accuracyColor =
            isHighAccuracyWiFi ? Colors.green : (isWiFiBased ? Colors.blue : Colors.orange);
        final sourceInfo = NetworkLocationService.getLocationSourceInfo(networkLoc);
        final accuracy = NetworkLocationService.getAccuracy(networkLoc);

        return Column(
          children: [
            // Map section
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
                              color: accuracyColor.shade600,
                              size: 48,
                            ),
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
              ),
            ),
            // Info panel
            Expanded(
              flex: 1,
              child: Container(
                color: cs.surface,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location type badge with source info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accuracyColor.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sourceInfo,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accuracyColor.shade700,
                              ),
                            ),
                          ),
                          if (accuracy != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accuracyColor.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                WiFiLocationService.getAccuracyDescription(
                                    accuracy),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: accuracyColor.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Location details
                      _buildInfoRow(
                        cs,
                        'Latitude:',
                        networkLoc['latitude'].toStringAsFixed(6),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Longitude:',
                        networkLoc['longitude'].toStringAsFixed(6),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Akurasi:',
                        accuracy != null
                            ? '${accuracy.toStringAsFixed(1)} m'
                            : 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Kota:',
                        networkLoc['city'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Region:',
                        networkLoc['region'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Negara:',
                        networkLoc['country'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'ISP/Provider:',
                        networkLoc['isp'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        cs,
                        'Sumber:',
                        networkLoc['source'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 16),
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoadingLocation ? null : _getNetworkLocation,
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
