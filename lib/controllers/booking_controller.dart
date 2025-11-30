import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../models/booking.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../models/hive_models.dart';
import '../controllers/storage_controller.dart';

class BookingController extends GetxController {
  final bookingData = BookingData().obs;
  final weatherService = WeatherService();
  final locationService = LocationService();

  final isLoadingWeather = false.obs;
  final selectedLocation = Rxn<BookingLocation>();
  final currentWeather = Rxn();
  final isSaving = false.obs;
  final selectedLocationMode = 'hybrid'.obs; // added location mode tracking

  final availableServices = <CleaningService>[
    CleaningService(
      id: '1',
      name: 'Indoor Cleaning',
      description: 'Pembersihan ruangan dalam (ruang tamu, kamar, dapur)',
      price: 250000,
      type: 'indoor',
      estimatedHours: 2,
    ),
    CleaningService(
      id: '2',
      name: 'Outdoor Cleaning',
      description: 'Pembersihan area luar (halaman, teras, garasi)',
      price: 350000,
      type: 'outdoor',
      estimatedHours: 3,
    ),
    CleaningService(
      id: '3',
      name: 'Deep Cleaning',
      description: 'Pembersihan menyeluruh mencakup semua area',
      price: 500000,
      type: 'deep',
      estimatedHours: 4,
    ),
    CleaningService(
      id: '4',
      name: 'Window Cleaning',
      description: 'Pembersihan jendela, kaca, dan frame',
      price: 200000,
      type: 'window',
      estimatedHours: 1,
    ),
  ];

  late StorageController storageController;
  final offlineQueue = <HiveBooking>[].obs;
  final localPhotoPaths = <String>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      // Get storage controller
      storageController = Get.find<StorageController>();

      // Wait for initialization
      if (!storageController.isInitialized.value) {
        print('[BookingController] Waiting for storage initialization...');
        await Future.delayed(const Duration(seconds: 2));
      }

      // Load offline queue
      _loadOfflineQueue();
      
      // Load last address if exists
      loadLastAddress();
      
      print('[BookingController] ✅ Initialized with ${offlineQueue.length} pending bookings');
    } catch (e) {
      print('[BookingController] ❌ Initialization error: $e');
      Get.snackbar('Error', 'Failed to initialize booking: $e');
    }
  }

  /// Load offline queue from Hive
  void _loadOfflineQueue() {
    try {
      offlineQueue.value = storageController.getPendingBookings();
      print('[BookingController] 📥 Loaded ${offlineQueue.length} pending bookings');
    } catch (e) {
      print('[BookingController] ❌ Load queue error: $e');
    }
  }

  /// Refresh offline queue
  void refreshOfflineQueue() {
    _loadOfflineQueue();
  }

  // ============ FORM DATA SETTERS ============

  void setCustomerName(String name) {
    bookingData.update((data) => data!.customerName = name);
  }

  void setPhoneNumber(String phone) {
    bookingData.update((data) => data!.phoneNumber = phone);
  }

  void selectService(CleaningService service) {
    bookingData.update((data) => data!.selectedService = service);
    print('[BookingController] Service selected: ${service.name}');
  }

  void setBookingDate(DateTime date) {
    bookingData.update((data) => data!.bookingDate = date);
  }

  void setBookingTime(TimeOfDay time) {
    bookingData.update((data) => data!.bookingTime = time);
  }

  void setNotes(String notes) {
    bookingData.update((data) => data!.notes = notes);
    print('[BookingController] Notes updated: ${notes.substring(0, notes.length > 20 ? 20 : notes.length)}...');
  }

  void setLocalPhotoPaths(List<String> paths) {
    localPhotoPaths.value = paths;
    print('[BookingController] Local photos updated: ${paths.length} photos');
  }

  // ============ LOCATION & WEATHER ============

  Future<void> loadWeatherForLocation(double lat, double lng) async {
    isLoadingWeather.value = true;
    try {
      // Check cache first
      final locationKey = '${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
      final cached = storageController.getCachedWeather(locationKey);
      
      if (cached != null && !cached.isExpired()) {
        print('[BookingController] ☁️ Using cached weather');
        // Convert cached weather to WeatherData (you need to create this conversion)
        // For now, fetch fresh data
      }
      
      final weather = await weatherService.getWeatherByCoordinates(
        latitude: lat,
        longitude: lng,
        location: 'Lokasi Pilihan',
      );
      
      currentWeather.value = weather;
      
      // Cache the weather - ✅ GUNAKAN CONSTRUCTOR BARU
      final cacheWeather = HiveCachedWeather(
        locationKey: locationKey,
        temperature: weather.temperature,
        windSpeed: weather.windSpeed,
        rainProbability: weather.rainProbability.toInt(),
        cachedAt: DateTime.now(),
      );
      
      await storageController.cacheWeather(cacheWeather);
      
      print('[BookingController] 🌤️ Weather loaded: ${weather.temperature}°C');
    } catch (e) {
      print('[BookingController] ❌ Weather load error: $e');
    } finally {
      isLoadingWeather.value = false;
    }
  }

  void setLocation(double lat, double lng, String address, {String mode = 'hybrid'}) {
    selectedLocationMode.value = mode; // store location mode
    selectedLocation.value = BookingLocation(
      latitude: lat,
      longitude: lng,
      address: address,
    );
    bookingData.update((data) => data!.location = selectedLocation.value);
    
    final lastLocation = HiveLastLocation(
      latitude: lat,
      longitude: lng,
      address: address,
      usedAt: DateTime.now(),
    );
    
    storageController.saveLastLocation(lastLocation);
    
    print('[BookingController] 📍 Location set: $address (Mode: $mode)');
  }

  void clearLocation() {
    selectedLocation.value = null;
    selectedLocationMode.value = 'hybrid';
    bookingData.update((data) {
      data!.location = null;
    });
    print('[BookingController] 🗑️ Location cleared');
  }

  // ============ CALCULATIONS ============

  Future<double> getETA() async {
    if (selectedLocation.value == null) return 0;
    final distance = selectedLocation.value!.distanceFromUMM();
    return distance / 40 * 60; // minutes (40 km/h average)
  }

  double calculateEstimatedPrice() {
    if (bookingData.value.selectedService == null) return 0;
    return bookingData.value.calculateTotalPrice();
  }

  double getDistanceFee() {
    if (bookingData.value.location == null) return 0;
    final distance = bookingData.value.location!.distanceFromUMM();
    return distance * 15000; // Rp per km
  }

  double getBasePrice() {
    return bookingData.value.selectedService?.price ?? 0;
  }

  bool hasWeatherWarnings() {
    if (currentWeather.value == null) return false;
    final weather = currentWeather.value;
    return !weather.isWindSafe() || weather.rainProbability > 50;
  }

  // ============ SUBMIT BOOKING ============

  Future<bool> submitBooking() async {
    // Validation
    if (bookingData.value.customerName.isEmpty) {
      Get.snackbar('Error', 'Nama pelanggan harus diisi');
      return false;
    }
    
    if (bookingData.value.phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Nomor telepon harus diisi');
      return false;
    }
    
    if (bookingData.value.selectedService == null) {
      Get.snackbar('Error', 'Pilih layanan terlebih dahulu');
      return false;
    }
    
    if (bookingData.value.location == null) {
      Get.snackbar('Error', 'Pilih lokasi terlebih dahulu');
      return false;
    }
    
    if (bookingData.value.bookingDate == null) {
      Get.snackbar('Error', 'Pilih tanggal booking');
      return false;
    }
    
    if (bookingData.value.bookingTime == null) {
      Get.snackbar('Error', 'Pilih waktu booking');
      return false;
    }
    
    // Validate booking time
    if (!bookingData.value.isValidBookingTime()) {
      Get.snackbar(
        'Error', 
        bookingData.value.getBookingTimeError(),
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
    
    // Check if location is too far
    if (bookingData.value.location!.isTooFar()) {
      Get.snackbar(
        'Error',
        'Lokasi terlalu jauh (ETA > 200 menit). Silakan pilih lokasi yang lebih dekat.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
    
    isSaving.value = true;
    
    try {
      // ✅ GUNAKAN CONSTRUCTOR BARU YANG AMAN
      final hiveBooking = HiveBooking(
        customerName: bookingData.value.customerName,
        phoneNumber: bookingData.value.phoneNumber,
        serviceName: bookingData.value.selectedService!.name,
        latitude: bookingData.value.location!.latitude,
        longitude: bookingData.value.location!.longitude,
        address: bookingData.value.location!.address,
        bookingDate: bookingData.value.bookingDate!,
        bookingTime: bookingData.value.bookingTime!.format(Get.context!),
        totalPrice: bookingData.value.calculateTotalPrice(),
        status: 'pending',
        notes: bookingData.value.notes,
        localPhotoPaths: localPhotoPaths.toList(),
        synced: false,
      );
      
      // Save using storage controller (offline-first)
      final success = await storageController.saveBookingLocally(hiveBooking);
      
      if (success) {
        // Save last address to prefs
        await storageController.setLastAddress(
          bookingData.value.location!.address
        );
        
        // Upload photos jika ada dan online
        if (localPhotoPaths.isNotEmpty && storageController.isOnline.value) {
          await _uploadPhotos(hiveBooking.id);
        }
        
        // Refresh offline queue
        refreshOfflineQueue();
        
        // Reset booking data
        bookingData.value = BookingData();
        selectedLocation.value = null;
        currentWeather.value = null;
        localPhotoPaths.clear();
        
        // Show success message
        Get.snackbar(
          'Success',
          storageController.isOnline.value
              ? 'Booking berhasil disimpan dan telah tersinkronisasi!'
              : 'Booking berhasil disimpan offline. Akan tersinkronisasi saat online.',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 3),
        );
        
        print('[BookingController] ✅ Booking submitted successfully');
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Gagal menyimpan booking. Silakan coba lagi.',
          backgroundColor: Colors.red.shade100,
        );
        return false;
      }
    } catch (e) {
      print('[BookingController] ❌ Submit error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _uploadPhotos(String bookingId) async {
    try {
      final List<String> uploadedUrls = [];
      
      for (final localPath in localPhotoPaths) {
        final file = File(localPath);
        if (await file.exists()) {
          final url = await storageController.supabaseService.uploadPhoto(file, bookingId);
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }
      
      // Update booking dengan cloud photo URLs
      if (uploadedUrls.isNotEmpty) {
        final booking = storageController.getBooking(bookingId);
        if (booking != null) {
          booking.photoUrls = uploadedUrls;
          await storageController.hiveService.updateBooking(booking);
          
          // Update di Supabase juga
          await storageController.supabaseService.updateBookingPhotos(bookingId, uploadedUrls);
        }
      }
    } catch (e) {
      print('[BookingController] ❌ Photo upload error: $e');
    }
  }

  // ============ LOAD LAST DATA ============

  void loadLastAddress() {
    try {
      final lastAddress = storageController.getLastAddress();
      if (lastAddress.isNotEmpty) {
        print('[BookingController] 📍 Loaded last address: $lastAddress');
      }
      
      final lastLocation = storageController.getLastLocation();
      if (lastLocation != null) {
        print('[BookingController] 📍 Last location: ${lastLocation.address}');
      }
    } catch (e) {
      print('[BookingController] ❌ Load last address error: $e');
    }
  }

  // ============ MANUAL SYNC ============

  Future<void> triggerManualSync() async {
    try {
      await storageController.syncNow();
      refreshOfflineQueue();
      Get.snackbar(
        'Success',
        'Sinkronisasi selesai',
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      print('[BookingController] ❌ Manual sync error: $e');
      Get.snackbar('Error', 'Sinkronisasi gagal: $e');
    }
  }

  // ============ DELETE BOOKING ============

  Future<bool> deleteBooking(String id) async {
    try {
      final success = await storageController.deleteBooking(id);
      if (success) {
        refreshOfflineQueue();
        Get.snackbar('Success', 'Booking berhasil dihapus');
        return true;
      }
      return false;
    } catch (e) {
      print('[BookingController] ❌ Delete error: $e');
      Get.snackbar('Error', 'Gagal menghapus booking: $e');
      return false;
    }
  }

  // ============ BOOKING STATUS MANAGEMENT ============

  /// Mark booking as completed untuk enable notes
  Future<bool> markBookingAsCompleted(String bookingId) async {
    try {
      final booking = storageController.getBooking(bookingId);
      if (booking == null) {
        Get.snackbar('Error', 'Booking tidak ditemukan');
        return false;
      }
      
      booking.status = 'completed';
      booking.updatedAt = DateTime.now();
      
      await storageController.hiveService.updateBooking(booking);
      
      // Sync to Supabase if authenticated
      if (storageController.isOnline.value && storageController.supabaseService.isAuthenticated) {
        await storageController.supabaseService.updateBookingStatus(bookingId, 'completed');
      }
      
      refreshOfflineQueue();
      
      Get.snackbar(
        'Success',
        'Booking ditandai sebagai selesai',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[BookingController] ✅ Booking marked as completed: $bookingId');
      return true;
    } catch (e) {
      print('[BookingController] ❌ Mark complete error: $e');
      Get.snackbar('Error', 'Gagal menandai booking: $e');
      return false;
    }
  }
  
  /// Get completed bookings (for notes management)
  List<HiveBooking> getCompletedBookings() {
    try {
      final completed = storageController.getAllBookings()
          .where((b) => b.status == 'completed' || b.status == 'finished')
          .toList();
      
      print('[BookingController] 📊 Found ${completed.length} completed bookings');
      return completed;
    } catch (e) {
      print('[BookingController] ❌ Get completed error: $e');
      return [];
    }
  }

  @override
  void onClose() {
    print('[BookingController] 🛑 Disposed');
    super.onClose();
  }
}
