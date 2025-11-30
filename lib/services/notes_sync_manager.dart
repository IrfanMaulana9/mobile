import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/hive_models.dart';
import '../models/storage_performance.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// Dedicated Notes Sync Manager - Auto sync when online
class NotesSyncManager {
  static final NotesSyncManager _instance = NotesSyncManager._internal();
  
  factory NotesSyncManager() => _instance;
  
  NotesSyncManager._internal();
  
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
      print('[NotesSyncManager] ⚠️ Already initialized');
      return;
    }
    
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          if (results.contains(ConnectivityResult.mobile) || 
              results.contains(ConnectivityResult.wifi)) {
            print('[NotesSyncManager] 📶 Online detected, syncing pending notes...');
            _syncPendingNotes();
          } else {
            print('[NotesSyncManager] 📴 Offline detected');
          }
        },
      );
      
      _isInitialized = true;
      print('[NotesSyncManager] ✅ Initialized successfully');
      
      // Initial sync if online
      final isOnline = await this.isOnline();
      if (isOnline) {
        print('[NotesSyncManager] 📶 Currently online, starting initial notes sync...');
        await _syncPendingNotes();
      }
    } catch (e) {
      print('[NotesSyncManager] ❌ Initialization error: $e');
    }
  }
  
  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) || 
             results.contains(ConnectivityResult.wifi);
    } catch (e) {
      print('[NotesSyncManager] ❌ Check online error: $e');
      return false;
    }
  }
  
  /// Sync all pending notes to Supabase
  Future<void> _syncPendingNotes() async {
    if (_isSyncing) {
      print('[NotesSyncManager] ⚠️ Sync already in progress');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // Check online status
      final online = await isOnline();
      if (!online) {
        print('[NotesSyncManager] 📴 Device offline, skipping sync');
        _isSyncing = false;
        return;
      }
      
      // Get pending notes (synced = false)
      final pendingNotes = _hiveService.getNotesByUserId('').where((note) => !note.synced).toList();
      
      if (pendingNotes.isEmpty) {
        print('[NotesSyncManager] ✅ No pending notes to sync');
        _isSyncing = false;
        return;
      }
      
      print('[NotesSyncManager] 🔄 Starting sync of ${pendingNotes.length} notes...');
      
      int successCount = 0;
      int failCount = 0;
      
      for (final note in pendingNotes) {
        final stopwatch = Stopwatch()..start();
        
        try {
          // Try to insert or update to Supabase
          final result = await _supabaseService.insertOrUpdateNote(note);
          
          stopwatch.stop();
          
          if (result != null) {
            // Mark as synced in Hive
            note.supabaseId = result;
            note.synced = true;
            await _hiveService.updateNote(note);
            
            _tracker.addLog(StoragePerformanceLog(
              operation: 'write',
              storageType: 'sync',
              dataKey: 'sync_note_${note.id}',
              executionTimeMs: stopwatch.elapsedMilliseconds,
              success: true,
              timestamp: DateTime.now(),
            ));
            
            successCount++;
            print('[NotesSyncManager] ✅ Synced note: ${note.id} - ${note.title}');
          } else {
            _tracker.addLog(StoragePerformanceLog(
              operation: 'write',
              storageType: 'sync',
              dataKey: 'sync_note_${note.id}',
              executionTimeMs: stopwatch.elapsedMilliseconds,
              success: false,
              errorMessage: 'Insert failed',
              timestamp: DateTime.now(),
            ));
            
            failCount++;
            print('[NotesSyncManager] ❌ Failed to sync note: ${note.id}');
          }
        } catch (e) {
          stopwatch.stop();
          
          _tracker.addLog(StoragePerformanceLog(
            operation: 'write',
            storageType: 'sync',
            dataKey: 'sync_note_${note.id}',
            executionTimeMs: stopwatch.elapsedMilliseconds,
            success: false,
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
          ));
          
          failCount++;
          print('[NotesSyncManager] ❌ Sync error for ${note.id}: $e');
        }
        
        // Small delay between syncs
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      print('[NotesSyncManager] ✅ Sync completed: $successCount success, $failCount failed');
    } catch (e) {
      print('[NotesSyncManager] ❌ Sync process error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Manual trigger for sync
  Future<void> syncNow() async {
    print('[NotesSyncManager] 🔄 Manual sync triggered');
    await _syncPendingNotes();
  }
  
  /// Get pending notes count
  int getPendingNotesCount() {
    try {
      final allNotes = _hiveService.getAllNotes();
      return allNotes.where((note) => !note.synced).toList().length;
    } catch (e) {
      print('[NotesSyncManager] ❌ Get pending count error: $e');
      return 0;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    print('[NotesSyncManager] 🛑 Disposed');
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
