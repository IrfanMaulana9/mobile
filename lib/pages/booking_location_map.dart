import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../controllers/booking_controller.dart';
import '../controllers/gps_controller.dart';
import '../models/booking.dart';
import '../services/location_mode_service.dart';
import '../widgets/location_mode_selector.dart';

class LocationMapPicker extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;

  const LocationMapPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final controller = Get.find<BookingController>();
  late MapController _mapController;
  late LatLng _selectedLocation;
  String _selectedAddress = 'Sentuh peta untuk memilih lokasi pembersihan';
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  double _mapZoom = 14;
  GPSController? _gpsController;
  String _selectedMode = 'hybrid';
  
  StreamSubscription? _liveLocationSubscription;
  bool _isLiveTrackingActive = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Center on Malang city
    _selectedLocation = const LatLng(-7.985, 112.632);
    _selectedAddress = 'Sentuh peta untuk memilih lokasi pembersihan';
    
    try {
      _gpsController = Get.find<GPSController>();
      print('[LocationMapPicker] GPS Controller found');
    } catch (e) {
      print('[LocationMapPicker] GPS Controller not found: $e');
      _gpsController = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    
    _liveLocationSubscription?.cancel();
    _isLiveTrackingActive = false;
    
    super.dispose();
  }

  Future<void> _loadAddress(double lat, double lng) async {
    setState(() => _isLoading = true);
    try {
      final address = await controller.locationService.reverseGeocode(lat, lng);
      setState(() {
        _selectedAddress = address;
        _isLoading = false;
      });
    } catch (e) {
      print('[LocationMapPicker] Error loading address: $e');
      setState(() {
        _selectedAddress = 'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await controller.locationService.searchPlaces(query);
      setState(() => _searchResults = results);
    } catch (e) {
      print('[LocationMapPicker] Search error: $e');
      setState(() => _searchResults = []);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final newLocation = LatLng(result['lat'], result['lon']);
    setState(() {
      _selectedLocation = newLocation;
      _selectedAddress = result['display_name'];
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });
    _mapController.move(newLocation, 17.0);
  }

  Future<void> _useCurrentLocation() async {
    if (_gpsController == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS Controller tidak tersedia')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Initialize GPS jika belum
      if (!_gpsController!.isGPSInitialized.value) {
        print('[LocationMapPicker] Initializing GPS...');
        await _gpsController!.initializeGPS();
      }

      final locationModeService = LocationModeService();
      
      final location = await locationModeService.getCurrentLocation(_selectedMode);
      
      if (location != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _selectedAddress = location.address;
        });
        
        // Animate map ke lokasi baru
        _mapController.move(_selectedLocation, 17.0);
        
        print('[LocationMapPicker] Location acquired: ${location.address} (Mode: $_selectedMode)');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi ditemukan (${LocationModeService.getModeIcon(_selectedMode)})'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan lokasi. Coba mode lain atau tap pada peta'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[LocationMapPicker] Error using current location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startLiveLocationTracking() {
    if (_gpsController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS tidak tersedia')),
      );
      return;
    }

    if (_isLiveTrackingActive) {
      _stopLiveLocationTracking();
      return;
    }

    print('[LocationMapPicker] Starting live location tracking...');
    
    setState(() => _isLiveTrackingActive = true);

    // Subscribe ke position stream dari GPS controller
    _liveLocationSubscription = _gpsController!.currentPosition.listen((position) {
      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Update address
        _loadAddress(position.latitude, position.longitude);
        
        // Auto-follow map
        _mapController.move(_selectedLocation, 17.0);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live tracking dimulai'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopLiveLocationTracking() {
    print('[LocationMapPicker] Stopping live location tracking...');
    
    _liveLocationSubscription?.cancel();
    _liveLocationSubscription = null;
    
    setState(() => _isLiveTrackingActive = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live tracking dihentikan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  double _calculateDistance() {
    final location = BookingLocation(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: _selectedAddress,
    );
    return location.distanceFromUMM();
  }

  double _calculateETA() {
    final location = BookingLocation(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: _selectedAddress,
    );
    return location.calculateETA();
  }

  String _getDistanceFeeText() {
    final location = BookingLocation(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: _selectedAddress,
    );
    return location.getDistanceFeeDescription();
  }

  bool _isTooFar() {
    final location = BookingLocation(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: _selectedAddress,
    );
    return location.isTooFar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final distance = _calculateDistance();
    final eta = _calculateETA();
    final distanceFeeText = _getDistanceFeeText();
    final isTooFar = _isTooFar();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Pembersihan'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: LocationModeSelector(
                    selectedMode: _selectedMode,
                    onModeChanged: (mode) {
                      setState(() => _selectedMode = mode);
                      print('[LocationMapPicker] Location mode changed to: $mode');
                    },
                  ),
                ),
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: _mapZoom,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                          _selectedAddress = 'Lokasi: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                          _loadAddress(point.latitude, point.longitude);
                        });
                        
                        // Stop live tracking jika user tap manual
                        if (_isLiveTrackingActive) {
                          _stopLiveLocationTracking();
                        }
                      },
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag.doubleTapZoom,
                      ),
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
                            point: _selectedLocation,
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.location_on,
                              color: _isTooFar() ? cs.error : cs.error,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: cs.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Koordinat Terpilih',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Jarak dari UMM',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${distance.toStringAsFixed(2)} km',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimasi ETA',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${eta.toStringAsFixed(0)} menit',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isTooFar ? cs.error : cs.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Biaya Jarak',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  distanceFeeText,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isTooFar ? cs.error : Colors.green,
                                      ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      
                      if (_gpsController != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _useCurrentLocation,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Get Lokasi Saat Ini'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.tertiary,
                                    foregroundColor: cs.onTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _isLiveTrackingActive ? _stopLiveLocationTracking : _startLiveLocationTracking,
                                  icon: Icon(_isLiveTrackingActive ? Icons.stop : Icons.play_arrow),
                                  label: Text(_isLiveTrackingActive ? 'Stop' : 'Live Track'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLiveTrackingActive ? cs.error : cs.secondary,
                                    foregroundColor: _isLiveTrackingActive ? cs.onError : cs.onSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) async {
                          await _searchLocation(value);
                          setState(() => _showSearchResults = value.isNotEmpty);
                        },
                        decoration: InputDecoration(
                          labelText: 'Cari Lokasi di Malang',
                          hintText: 'Contoh: Jalan Soekarno, Mall, Sekolah',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                        ),
                      ),
                      if (_showSearchResults && _searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on, size: 20),
                                title: Text(
                                  result['display_name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_isLiveTrackingActive) {
                          _stopLiveLocationTracking();
                        }
                        Get.back();
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isTooFar
                          ? null
                          : () {
                              if (_isLiveTrackingActive) {
                                _stopLiveLocationTracking();
                              }
                              
                              widget.onLocationSelected(
                                _selectedLocation.latitude,
                                _selectedLocation.longitude,
                                _selectedAddress,
                              );
                              Get.back();
                            },
                      icon: const Icon(Icons.check_circle),
                      label: Text(isTooFar ? 'Terlalu Jauh' : 'Konfirmasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
