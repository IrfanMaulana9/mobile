import 'package:get/get.dart';
import 'dart:io';
import '../services/prefs_service.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/offline_sync_manager.dart';
import '../models/hive_models.dart';
import '../models/user_preference.dart';

/// Storage Controller - Central hub untuk semua storage operations dengan notes & photos support
class StorageController extends GetxController {
  late PrefsService prefsService;
  late HiveService hiveService;
  late SupabaseService supabaseService;
  late OfflineSyncManager syncManager;
  
  final isOnline = true.obs;
  final syncInProgress = false.obs;
  final pendingBookingsCount = 0.obs;
  final isInitialized = false.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeServices();
  }
  
  /// Initialize all storage services
  Future<void> _initializeServices() async {
    try {
      print('[StorageController] 🚀 Initializing storage services...');
      
      // 1. Initialize SharedPreferences
      prefsService = PrefsService();
      await prefsService.init();
      print('[StorageController] ✅ SharedPreferences ready');
      
      // 2. Initialize Hive
      hiveService = HiveService();
      await hiveService.init();
      print('[StorageController] ✅ Hive ready');
      
      // 3. Initialize Supabase dengan .env
      supabaseService = SupabaseService();
      await supabaseService.init();
      print('[StorageController] ✅ Supabase ready (waiting for auth)');
      
      // 4. Initialize Sync Manager
      syncManager = OfflineSyncManager();
      await syncManager.init();
      print('[StorageController] ✅ Sync Manager ready');
      
      // 5. Update status
      isOnline.value = await syncManager.isOnline();
      pendingBookingsCount.value = syncManager.getPendingCount();
      isInitialized.value = true;
      
      print('[StorageController] ✅ All services initialized successfully');
      print('[StorageController] 📊 Pending bookings: ${pendingBookingsCount.value}');
    } catch (e) {
      print('[StorageController] ❌ Initialization failed: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize storage: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // ============ PREFERENCES MANAGEMENT ============
  
  /// Get user preferences
  Future<UserPreference> getUserPreferences() async {
    return await prefsService.getUserPreferences();
  }
  
  /// Save user preferences
  Future<bool> saveUserPreferences(UserPreference preferences) async {
    return await prefsService.saveUserPreferences(preferences);
  }
  
  /// Set theme
  Future<void> setTheme(String theme) async {
    await prefsService.setTheme(theme);
    print('[StorageController] Theme set to: $theme');
  }
  
  /// Get theme
  String getTheme() => prefsService.getTheme();
  
  /// Set last address
  Future<void> setLastAddress(String address) async {
    await prefsService.setLastAddress(address);
  }
  
  /// Get last address
  String getLastAddress() => prefsService.getLastAddress();
  
  /// Set last city
  Future<void> setLastCity(String city) async {
    await prefsService.setLastCity(city);
  }
  
  /// Get last city
  String getLastCity() => prefsService.getLastCity();
  
  // ============ BOOKING MANAGEMENT ============
  
  /// Save booking locally (Hive) dengan notes & photos support
  Future<bool> saveBookingLocally(HiveBooking booking) async {
    try {
      final online = await syncManager.isOnline();
      
      // Always save to Hive first (offline-first approach)
      await hiveService.addBooking(booking);
      print('[StorageController] ✅ Booking saved to Hive: ${booking.id}');
      print('[StorageController]    Notes: ${booking.notes ?? "No notes"}');
      print('[StorageController]    Local Photos: ${booking.localPhotoPaths?.length ?? 0}');
      
      if (online && supabaseService.isAuthenticated) {
        // If online, try sync immediately dengan notes & photos
        print('[StorageController] 📶 Online, attempting immediate sync...');
        final result = await supabaseService.insertBooking(booking);
        
        if (result != null) {
          // Mark as synced
          await hiveService.markBookingAsSynced(booking.id);
          
          // Upload photos jika ada
          if (booking.localPhotoPaths != null && booking.localPhotoPaths!.isNotEmpty) {
            await _uploadBookingPhotos(booking);
          }
          
          print('[StorageController] ✅ Booking synced immediately: ${booking.id}');
        } else {
          // Queue for later sync
          print('[StorageController] ⚠️ Immediate sync failed, queued for later');
        }
      } else {
        // Queue for offline sync
        print('[StorageController] 📴 Offline, booking dengan notes & photos queued for sync');
      }
      
      // Update pending count
      pendingBookingsCount.value = syncManager.getPendingCount();
      
      // Save last address to prefs
      await prefsService.setLastAddress(booking.address);
      
      return true;
    } catch (e) {
      print('[StorageController] ❌ Error saving booking: $e');
      Get.snackbar(
        'Error',
        'Failed to save booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
  
  /// Upload booking photos ke Supabase
  Future<void> _uploadBookingPhotos(HiveBooking booking) async {
    try {
      final List<String> uploadedUrls = [];
      
      for (final localPath in booking.localPhotoPaths!) {
        final file = File(localPath);
        if (await file.exists()) {
          final url = await supabaseService.uploadPhoto(file, booking.id);
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }
      
      // Update booking dengan cloud photo URLs
      if (uploadedUrls.isNotEmpty) {
        booking.photoUrls = uploadedUrls;
        await hiveService.updateBooking(booking);
        
        // Juga update di Supabase
        await supabaseService.updateBookingPhotos(booking.id, uploadedUrls);
        
        print('[StorageController] ✅ ${uploadedUrls.length} photos uploaded for booking: ${booking.id}');
      }
    } catch (e) {
      print('[StorageController] ❌ Photo upload error: $e');
    }
  }
  
  /// Get all bookings from Hive
  List<HiveBooking> getAllBookings() => hiveService.getAllBookings();
  
  /// Get booking by ID
  HiveBooking? getBooking(String id) => hiveService.getBooking(id);
  
  /// Get pending bookings
  List<HiveBooking> getPendingBookings() => hiveService.getPendingBookings();
  
  /// Delete booking
  Future<bool> deleteBooking(String id) async {
    try {
      // Delete from Hive
      await hiveService.deleteBooking(id);
      
      // If online and authenticated, delete from Supabase
      if (isOnline.value && supabaseService.isAuthenticated) {
        await supabaseService.deleteBooking(id);
      }
      
      pendingBookingsCount.value = syncManager.getPendingCount();
      print('[StorageController] ✅ Booking deleted: $id');
      return true;
    } catch (e) {
      print('[StorageController] ❌ Delete error: $e');
      return false;
    }
  }
  
  // ============ SYNC MANAGEMENT ============
  
  /// Manual sync trigger
  Future<void> syncNow() async {
    syncInProgress.value = true;
    try {
      print('[StorageController] 🔄 Manual sync started...');
      await syncManager.syncNow();
      pendingBookingsCount.value = syncManager.getPendingCount();
      
      Get.snackbar(
        'Success',
        'Sync completed. Pending: ${pendingBookingsCount.value}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('[StorageController] ❌ Sync error: $e');
      Get.snackbar(
        'Error',
        'Sync failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      syncInProgress.value = false;
    }
  }
  
  /// Check online status
  Future<void> checkOnlineStatus() async {
    isOnline.value = await syncManager.isOnline();
  }
  
  // ============ WEATHER CACHE ============
  
  /// Cache weather data
  Future<void> cacheWeather(HiveCachedWeather weather) async {
    await hiveService.cacheWeather(weather);
  }
  
  /// Get cached weather
  HiveCachedWeather? getCachedWeather(String locationKey) {
    return hiveService.getCachedWeather(locationKey);
  }
  
  /// Clear expired weather cache
  Future<void> clearExpiredWeatherCache() async {
    await hiveService.clearExpiredWeatherCache();
  }
  
  // ============ LOCATION HISTORY ============
  
  /// Save last location
  Future<void> saveLastLocation(HiveLastLocation location) async {
    
    await hiveService.saveLastLocation(location);
  }
  
  /// Get last location
  HiveLastLocation? getLastLocation() {
    return hiveService.getLastLocation();
  }
  
  // ============ PERFORMANCE REPORTING ============
  
  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    final prefsReport = prefsService.getPerformanceReport();
    final hiveReport = hiveService.getPerformanceReport();
    final supabaseReport = supabaseService.getPerformanceReport();
    final syncReport = syncManager.getPerformanceReport();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isOnline': isOnline.value,
      'pendingBookingsCount': pendingBookingsCount.value,
      'totalBookings': hiveService.getAllBookings().length,
      'prefs': prefsReport,
      'hive': hiveReport,
      'supabase': supabaseReport,
      'sync': syncReport,
    };
  }
  
  /// Clear all performance logs
  void clearAllLogs() {
    prefsService.clearPerformanceLogs();
    hiveService.clearPerformanceLogs();
    supabaseService.clearPerformanceLogs();
    syncManager.clearPerformanceLogs();
    print('[StorageController] 🗑️ All performance logs cleared');
  }
  
  /// Export performance report as JSON string
  String exportPerformanceReport() {
    return getPerformanceReport().toString();
  }
  
  // ============ CLEAR ALL DATA ============
  
  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      await prefsService.clear();
      await hiveService.clearAll();
      pendingBookingsCount.value = 0;
      
      Get.snackbar(
        'Success',
        'All data cleared',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      print('[StorageController] 🗑️ All data cleared');
    } catch (e) {
      print('[StorageController] ❌ Clear all error: $e');
    }
  }
  
  // ============ NOTES MANAGEMENT ============
  
  /// Get notes by booking ID
  

  
  /// Create new note for booking
  Future<bool> createNote(
    String bookingId, {
    required String title,
    required String content,
  }) async {
    try {
      final note = HiveNote(
        title: title,
        content: content,
      );
      
      await hiveService.addNote(note);
      print('[StorageController] ✅ Note created: ${note.id}');
      
      // Sync to Supabase if online
      if (isOnline.value && supabaseService.isAuthenticated) {
        final result = await supabaseService.insertOrUpdateNote(note);
        if (result != null) {
          note.supabaseId = result;
          note.synced = true;
          await hiveService.updateNote(note);
          print('[StorageController] ✅ Note synced to Supabase: ${note.id}');
        }
      }
      
      return true;
    } catch (e) {
      print('[StorageController] ❌ Error creating note: $e');
      return false;
    }
  }
  
  /// Update existing note
  Future<bool> updateNote(
    String noteId, {
    required String title,
    required String content,
  }) async {
    try {
      final note = hiveService.getNote(noteId);
      if (note == null) return false;
      
      note.title = title;
      note.content = content;
      note.synced = false;
      
      await hiveService.updateNote(note);
      print('[StorageController] ✅ Note updated: ${note.id}');
      
      // Sync to Supabase if online
      if (isOnline.value && supabaseService.isAuthenticated) {
        final result = await supabaseService.insertOrUpdateNote(note);
        if (result != null) {
          note.supabaseId = result;
          note.synced = true;
          await hiveService.updateNote(note);
          print('[StorageController] ✅ Note synced to Supabase: ${note.id}');
        }
      }
      
      return true;
    } catch (e) {
      print('[StorageController] ❌ Error updating note: $e');
      return false;
    }
  }
  
  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      final note = hiveService.getNote(noteId);
      
      // Delete from Supabase if exists
      if (note != null && note.supabaseId != null && supabaseService.isAuthenticated) {
        await supabaseService.deleteNote(note.supabaseId!);
      }
      
      // Delete from local storage
      await hiveService.deleteNote(noteId);
      print('[StorageController] ✅ Note deleted: $noteId');
      
      return true;
    } catch (e) {
      print('[StorageController] ❌ Error deleting note: $e');
      return false;
    }
  }
  
  /// Get all notes
  List<HiveNote> getAllNotes() {
    return hiveService.getAllNotes();
  }
  
  /// Get pending notes for sync
  List<HiveNote> getPendingNotes() {
    return hiveService.getPendingNotes();
  }
  
  @override
  void onClose() {
    syncManager.dispose();
    hiveService.close();
    super.onClose();
  }
}
