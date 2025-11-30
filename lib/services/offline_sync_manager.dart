import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/hive_models.dart';
import '../models/storage_performance.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// Offline Sync Manager - Auto sync when online
class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  
  factory OfflineSyncManager() => _instance;
  
  OfflineSyncManager._internal();
  
  final HiveService _hiveService = HiveService();
  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();
  final PerformanceTracker _tracker = PerformanceTracker();
  
  bool _isSyncing = false;
  bool _isInitialized = false;
  StreamSubscription? _connectivitySubscription;
  
  bool get isSyncing => _isSyncing;
  
  /// Initialize sync manager and setup connectivity listener
  Future<void> init() async {
    if (_isInitialized) {
      print('[OfflineSyncManager] ⚠️ Already initialized');
      return;
    }
    
    try {
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          if (results.contains(ConnectivityResult.mobile) || 
              results.contains(ConnectivityResult.wifi)) {
            print('[OfflineSyncManager] 📶 Online detected, syncing...');
            _syncPendingBookings();
          } else {
            print('[OfflineSyncManager] 📴 Offline detected');
          }
        },
      );
      
      _isInitialized = true;
      print('[OfflineSyncManager] ✅ Initialized successfully');
      
      // Initial sync if online
      final isOnline = await this.isOnline();
      if (isOnline) {
        print('[OfflineSyncManager] 📶 Currently online, starting initial sync...');
        await _syncPendingBookings();
      }
    } catch (e) {
      print('[OfflineSyncManager] ❌ Initialization error: $e');
    }
  }
  
  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) || 
             results.contains(ConnectivityResult.wifi);
    } catch (e) {
      print('[OfflineSyncManager] ❌ Check online error: $e');
      return false;
    }
  }
  
  /// Queue booking for offline sync
  Future<void> queueOfflineBooking(HiveBooking booking) async {
    try {
      booking.synced = false;
      await _hiveService.addBooking(booking);
      print('[OfflineSyncManager] 📥 Booking queued for offline: ${booking.id}');
    } catch (e) {
      print('[OfflineSyncManager] ❌ Queue error: $e');
    }
  }
  
  /// Sync all pending bookings to Supabase
  Future<void> _syncPendingBookings() async {
    if (_isSyncing) {
      print('[OfflineSyncManager] ⚠️ Sync already in progress');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // Check online status
      final online = await isOnline();
      if (!online) {
        print('[OfflineSyncManager] 📴 Device offline, skipping sync');
        _isSyncing = false;
        return;
      }
      
 
      
      // Get pending bookings
      final pendingBookings = _hiveService.getPendingBookings();
      
      if (pendingBookings.isEmpty) {
        print('[OfflineSyncManager] ✅ No pending bookings to sync');
        _isSyncing = false;
        return;
      }
      
      print('[OfflineSyncManager] 🔄 Starting sync of ${pendingBookings.length} bookings...');
      
      int successCount = 0;
      int failCount = 0;
      
      for (final booking in pendingBookings) {
        final stopwatch = Stopwatch()..start();
        
        try {
          // Try to insert to Supabase
          final result = await _supabaseService.insertBooking(booking);
          
          stopwatch.stop();
          
          if (result != null) {
            // Mark as synced in Hive
            await _hiveService.markBookingAsSynced(booking.id);
            
            _tracker.addLog(StoragePerformanceLog(
              operation: 'write',
              storageType: 'sync',
              dataKey: 'sync_${booking.id}',
              executionTimeMs: stopwatch.elapsedMilliseconds,
              success: true,
              timestamp: DateTime.now(),
            ));
            
            successCount++;
            print('[OfflineSyncManager] ✅ Synced: ${booking.id}');
          } else {
            _tracker.addLog(StoragePerformanceLog(
              operation: 'write',
              storageType: 'sync',
              dataKey: 'sync_${booking.id}',
              executionTimeMs: stopwatch.elapsedMilliseconds,
              success: false,
              errorMessage: 'Insert failed',
              timestamp: DateTime.now(),
            ));
            
            failCount++;
            print('[OfflineSyncManager] ❌ Failed to sync: ${booking.id}');
          }
        } catch (e) {
          stopwatch.stop();
          
          _tracker.addLog(StoragePerformanceLog(
            operation: 'write',
            storageType: 'sync',
            dataKey: 'sync_${booking.id}',
            executionTimeMs: stopwatch.elapsedMilliseconds,
            success: false,
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
          ));
          
          failCount++;
          print('[OfflineSyncManager] ❌ Sync error for ${booking.id}: $e');
        }
        
        // Small delay between syncs
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('[OfflineSyncManager] ✅ Sync completed: $successCount success, $failCount failed');
    } catch (e) {
      print('[OfflineSyncManager] ❌ Sync process error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Manual trigger for sync
  Future<void> syncNow() async {
    print('[OfflineSyncManager] 🔄 Manual sync triggered');
    await _syncPendingBookings();
  }
  
  /// Get pending bookings count
  int getPendingCount() {
    try {
      return _hiveService.getPendingBookingsCount();
    } catch (e) {
      print('[OfflineSyncManager] ❌ Get pending count error: $e');
      return 0;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    print('[OfflineSyncManager] 🛑 Disposed');
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