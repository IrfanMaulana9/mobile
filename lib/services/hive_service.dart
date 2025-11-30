import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';
import '../models/storage_performance.dart';
import '../adapters/hive_note_adapter.dart'; // Import manual adapter untuk HiveNote

/// Service untuk Hive - local structured storage
class HiveService {
  static final HiveService _instance = HiveService._internal();
  
  factory HiveService() => _instance;
  
  HiveService._internal();
  
  Box<HiveBooking>? _bookingBox;
  Box<HiveCachedWeather>? _weatherBox;
  Box<HiveLastLocation>? _locationBox;
  Box<HiveNote>? _noteBox;
  
  final PerformanceTracker _tracker = PerformanceTracker();
  
  bool get isInitialized => _bookingBox != null;
  
  /// Initialize Hive and open all boxes
  Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HiveBookingAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(HiveCachedWeatherAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(HiveLastLocationAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(HiveNoteAdapter()); // Manual adapter
      }
      
      // Open boxes
      _bookingBox = await Hive.openBox<HiveBooking>('bookings');
      _weatherBox = await Hive.openBox<HiveCachedWeather>('weather_cache');
      _locationBox = await Hive.openBox<HiveLastLocation>('locations');
      _noteBox = await Hive.openBox<HiveNote>('notes');
      
      print('[HiveService] ✅ Initialized successfully');
      print('[HiveService] 📦 Bookings: ${_bookingBox?.length ?? 0}');
      print('[HiveService] 🌤️ Weather cache: ${_weatherBox?.length ?? 0}');
      print('[HiveService] 📍 Locations: ${_locationBox?.length ?? 0}');
      print('[HiveService] 📝 Notes: ${_noteBox?.length ?? 0}');
    } catch (e) {
      print('[HiveService] ❌ Initialization failed: $e');
      rethrow;
    }
  }
  
  // ============ BOOKING CRUD ============
  
  /// Add new booking
  Future<void> addBooking(HiveBooking booking) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (booking.updatedAt == null) {
        booking.updatedAt = DateTime.now();
      }
      
      await _bookingBox?.put(booking.id, booking);
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${booking.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Booking added: ${booking.id}');
      print('[HiveService]    Notes: ${booking.notes ?? "No notes"}');
      print('[HiveService]    Local Photos: ${booking.localPhotoPaths?.length ?? 0}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${booking.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Add booking error: $e');
      rethrow;
    }
  }
  
  /// Get booking by ID
  HiveBooking? getBooking(String id) {
    final stopwatch = Stopwatch()..start();
    try {
      final booking = _bookingBox?.get(id);
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'booking_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return booking;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'booking_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Get all bookings
  List<HiveBooking> getAllBookings() {
    final stopwatch = Stopwatch()..start();
    try {
      final bookings = _bookingBox?.values.toList() ?? [];
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'all_bookings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return bookings;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'all_bookings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Get pending bookings (not synced)
  List<HiveBooking> getPendingBookings() {
    final stopwatch = Stopwatch()..start();
    try {
      final bookings = _bookingBox?.values
          .where((b) => !b.synced)
          .toList() ?? [];
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'pending_bookings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] 📤 Pending bookings: ${bookings.length}');
      return bookings;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'pending_bookings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Update booking
  Future<void> updateBooking(HiveBooking booking) async {
    final stopwatch = Stopwatch()..start();
    try {
      booking.updatedAt = DateTime.now();
      await booking.save();
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${booking.id}_update',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Booking updated: ${booking.id}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${booking.id}_update',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Update error: $e');
      rethrow;
    }
  }
  
  /// Mark booking as synced
  Future<void> markBookingAsSynced(String id) async {
    final stopwatch = Stopwatch()..start();
    try {
      final booking = _bookingBox?.get(id);
      if (booking != null) {
        booking.synced = true;
        booking.updatedAt = DateTime.now();
        await booking.save();
        
        stopwatch.stop();
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'hive',
          dataKey: 'booking_${id}_sync',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[HiveService] ✅ Booking marked as synced: $id');
      }
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${id}_sync',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Mark sync error: $e');
    }
  }
  
  /// Delete booking
  Future<void> deleteBooking(String id) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _bookingBox?.delete(id);
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${id}_delete',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Booking deleted: $id');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'booking_${id}_delete',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Delete error: $e');
      rethrow;
    }
  }
  
  /// Get pending bookings count
  int getPendingBookingsCount() {
    return getPendingBookings().length;
  }
  
  // ============ WEATHER CACHE ============
  
  /// Cache weather data
  Future<void> cacheWeather(HiveCachedWeather weather) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _weatherBox?.put(weather.locationKey, weather);
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'weather_${weather.locationKey}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ☁️ Weather cached: ${weather.locationKey}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'weather_${weather.locationKey}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Cache weather error: $e');
    }
  }
  
  /// Get cached weather
  HiveCachedWeather? getCachedWeather(String locationKey) {
    final stopwatch = Stopwatch()..start();
    try {
      final weather = _weatherBox?.get(locationKey);
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'weather_$locationKey',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      // Check if expired (6 hours)
      if (weather != null && weather.isExpired()) {
        _weatherBox?.delete(locationKey);
        print('[HiveService] 🗑️ Expired weather cache deleted: $locationKey');
        return null;
      }
      
      return weather;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'weather_$locationKey',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Clear expired weather cache
  Future<void> clearExpiredWeatherCache() async {
    try {
      final keys = _weatherBox?.keys.toList() ?? [];
      for (final key in keys) {
        final weather = _weatherBox?.get(key);
        if (weather != null && weather.isExpired()) {
          await _weatherBox?.delete(key);
        }
      }
      print('[HiveService] 🧹 Expired weather cache cleared');
    } catch (e) {
      print('[HiveService] ❌ Clear cache error: $e');
    }
  }
  
  // ============ LOCATION HISTORY ============
  
  /// Save last location
  Future<void> saveLastLocation(HiveLastLocation location) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _locationBox?.put('last_location', location);
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'last_location',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] 📍 Last location saved: ${location.address}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'last_location',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Save location error: $e');
    }
  }
  
  /// Get last location
  HiveLastLocation? getLastLocation() {
    final stopwatch = Stopwatch()..start();
    try {
      final location = _locationBox?.get('last_location');
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'last_location',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return location;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'last_location',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  // ============ NOTES CRUD ============
  
  /// Create new note (standalone - no booking ID)
  Future<void> addNote(HiveNote note) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (note.updatedAt == null) {
        note.updatedAt = DateTime.now();
      }
      
      await _noteBox?.put(note.id, note);
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${note.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Note added: ${note.id}');
      print('[HiveService]    Title: ${note.title}');
      print('[HiveService]    User ID: ${note.userId}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${note.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Add note error: $e');
      rethrow;
    }
  }
  
  /// Get note by ID with user isolation
  HiveNote? getNote(String id) {
    final stopwatch = Stopwatch()..start();
    try {
      final note = _noteBox?.get(id);
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'note_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return note;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'note_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Get notes by user ID ONLY (standalone - no booking)
  List<HiveNote> getNotesByUserId(String userId) {
    final stopwatch = Stopwatch()..start();
    try {
      final notes = _noteBox?.values
          .where((n) => n.userId == userId)
          .toList() ?? [];
      
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'notes_user_$userId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] 📝 Found ${notes.length} notes for user $userId');
      return notes;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'notes_user_$userId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Get all notes (admin only)
  List<HiveNote> getAllNotes() {
    final stopwatch = Stopwatch()..start();
    try {
      final notes = _noteBox?.values.toList() ?? [];
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'all_notes',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return notes;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'hive',
        dataKey: 'all_notes',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Update note
  Future<void> updateNote(HiveNote note) async {
    final stopwatch = Stopwatch()..start();
    try {
      note.updatedAt = DateTime.now();
      await note.save();
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${note.id}_update',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Note updated: ${note.id}');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${note.id}_update',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Update note error: $e');
      rethrow;
    }
  }
  
  /// Delete note
  Future<void> deleteNote(String id) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _noteBox?.delete(id);
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${id}_delete',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] ✅ Note deleted: $id');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'note_${id}_delete',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Delete note error: $e');
      rethrow;
    }
  }
  
  /// Get pending notes (not synced)
  List<HiveNote> getPendingNotes() {
    return _noteBox?.values
        .where((n) => !n.synced)
        .toList() ?? [];
  }
  
  /// Mark note as synced
  Future<void> markNoteAsSynced(String id) async {
    try {
      final note = _noteBox?.get(id);
      if (note != null) {
        note.synced = true;
        note.updatedAt = DateTime.now();
        await note.save();
        print('[HiveService] ✅ Note marked as synced: $id');
      }
    } catch (e) {
      print('[HiveService] ❌ Mark note sync error: $e');
    }
  }

  // ============ CLEAR ALL ============
  
  /// Clear all data
  Future<void> clearAll() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _bookingBox?.clear();
      await _weatherBox?.clear();
      await _locationBox?.clear();
      await _noteBox?.clear();
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'clear_all',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[HiveService] 🗑️ All data cleared');
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'hive',
        dataKey: 'clear_all',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[HiveService] ❌ Clear all error: $e');
    }
  }
  
  /// Close all boxes
  Future<void> close() async {
    await _bookingBox?.close();
    await _weatherBox?.close();
    await _locationBox?.close();
    await _noteBox?.close();
    print('[HiveService] 📦 All boxes closed');
  }
  
  // ============ PERFORMANCE ============
  
  PerformanceTracker getTracker() => _tracker;
  
  void clearPerformanceLogs() {
    _tracker.clearLogs();
  }
  
  Map<String, dynamic> getPerformanceReport() {
    return _tracker.getPerformanceReport();
  }
}