import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/storage_performance.dart';
import '../models/user_preference.dart';

/// Service untuk SharedPreferences - simple key-value storage
class PrefsService {
  static final PrefsService _instance = PrefsService._internal();
  
  factory PrefsService() => _instance;
  
  PrefsService._internal();
  
  SharedPreferences? _prefs;
  final PerformanceTracker _tracker = PerformanceTracker();
  
  bool get isInitialized => _prefs != null;
  
  /// Initialize SharedPreferences
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('[PrefsService] ✅ Initialized successfully');
    } catch (e) {
      print('[PrefsService] ❌ Initialization failed: $e');
      rethrow;
    }
  }
  
  // ============ USER PREFERENCES ============
  
  /// Get complete user preferences
  Future<UserPreference> getUserPreferences() async {
    final stopwatch = Stopwatch()..start();
    try {
      final jsonString = _prefs?.getString('user_preferences');
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'user_preferences',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserPreference.fromJson(json);
      }
      return UserPreference();
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'user_preferences',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return UserPreference();
    }
  }
  
  /// Save user preferences
  Future<bool> saveUserPreferences(UserPreference preferences) async {
    final stopwatch = Stopwatch()..start();
    try {
      final jsonString = jsonEncode(preferences.toJson());
      final result = await _prefs?.setString('user_preferences', jsonString) ?? false;
      
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'user_preferences',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      print('[PrefsService] User preferences saved: ${preferences.theme}');
      return result;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'user_preferences',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      print('[PrefsService] Save error: $e');
      return false;
    }
  }
  
  // ============ THEME ============
  
  Future<bool> setTheme(String theme) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.setString('app_theme', theme) ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'app_theme',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      print('[PrefsService] Theme set to: $theme');
      return result;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'app_theme',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  String getTheme() {
    final stopwatch = Stopwatch()..start();
    try {
      final theme = _prefs?.getString('app_theme') ?? 'system';
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'app_theme',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return theme;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'app_theme',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return 'system';
    }
  }
  
  // ============ LAST ADDRESS ============
  
  Future<bool> setLastAddress(String address) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.setString('last_address', address) ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'last_address',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'last_address',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  String getLastAddress() {
    final stopwatch = Stopwatch()..start();
    try {
      final address = _prefs?.getString('last_address') ?? '';
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'last_address',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return address;
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'last_address',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return '';
    }
  }
  
  // ============ LAST CITY ============
  
  Future<bool> setLastCity(String city) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.setString('last_city', city) ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'last_city',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (e) {
      stopwatch.stop();
      return false;
    }
  }
  
  String getLastCity() {
    final stopwatch = Stopwatch()..start();
    try {
      final city = _prefs?.getString('last_city') ?? 'Jakarta';
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'last_city',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return city;
    } catch (e) {
      stopwatch.stop();
      return 'Jakarta';
    }
  }
  
  // ============ NOTIFICATIONS ============
  
  Future<bool> setNotificationsEnabled(bool enabled) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.setBool('notifications_enabled', enabled) ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'notifications_enabled',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (e) {
      stopwatch.stop();
      return false;
    }
  }
  
  bool getNotificationsEnabled() {
    final stopwatch = Stopwatch()..start();
    try {
      final enabled = _prefs?.getBool('notifications_enabled') ?? true;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: 'notifications_enabled',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return enabled;
    } catch (e) {
      stopwatch.stop();
      return true;
    }
  }
  
  // ============ FIRST RUN ============
  
  Future<bool> setFirstRun(bool isFirstRun) async {
    return await _prefs?.setBool('is_first_run', isFirstRun) ?? false;
  }
  
  bool isFirstRun() {
    return _prefs?.getBool('is_first_run') ?? true;
  }
  
  // ============ GENERIC METHODS ============
  
  Future<bool> setString(String key, String value) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.setString(key, value) ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: key,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (e) {
      stopwatch.stop();
      return false;
    }
  }
  
  String? getString(String key) {
    final stopwatch = Stopwatch()..start();
    try {
      final value = _prefs?.getString(key);
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'prefs',
        dataKey: key,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return value;
    } catch (e) {
      stopwatch.stop();
      return null;
    }
  }
  
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }
  
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }
  
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }
  
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }
  
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }
  
  // ============ CLEAR ============
  
  Future<bool> clear() async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _prefs?.clear() ?? false;
      stopwatch.stop();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'prefs',
        dataKey: 'clear_all',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: result,
        timestamp: DateTime.now(),
      ));
      
      print('[PrefsService] All data cleared');
      return result;
    } catch (e) {
      stopwatch.stop();
      return false;
    }
  }
  
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
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