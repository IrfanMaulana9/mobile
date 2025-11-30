import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/hive_models.dart';
import '../models/storage_performance.dart';

/// Service untuk Supabase - cloud storage, auth, dan realtime
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  late final String _supabaseUrl;
  late final String _supabaseKey;
  
  final String _apiPath = '/rest/v1';
  final String _storagePath = '/storage/v1';
  
  String _authToken = '';
  String _userId = '';
  String _userEmail = '';
  
  final PerformanceTracker _tracker = PerformanceTracker();
  
  bool get isAuthenticated => _authToken.isNotEmpty;
  String get userId => _userId;
  String get userEmail => _userEmail;
  
  /// Initialize Supabase service dengan credentials
  Future<void> init() async {
    try {
      _supabaseUrl = 'https://fnnaqvyjxlquoqhgniqq.supabase.co';
      _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmFxdnlqeGxxdW9xaGduaXFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyOTQwNjIsImV4cCI6MjA3ODg3MDA2Mn0.NFDTQlg0hIIaoLg_6TbVth1-nXBBE7BEIp9-206EjMQ';
      
      if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
        throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
      }
      
      print('[SupabaseService] ✅ Initialized with hardcoded credentials');
      print('[SupabaseService] 📍 URL: $_supabaseUrl');
    } catch (e) {
      print('[SupabaseService] ❌ Initialization error: $e');
      rethrow;
    }
  }
  
  // ============ AUTHENTICATION ============
  
  /// Sign up new user
  Future<bool> signUp(String email, String password) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': _supabaseKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response structures
        if (data['access_token'] != null) {
          _authToken = data['access_token'];
          _userId = data['user']?['id'] ?? '';
          _userEmail = data['user']?['email'] ?? email;
        } else if (data['session'] != null) {
          _authToken = data['session']['access_token'] ?? '';
          _userId = data['user']?['id'] ?? '';
          _userEmail = data['user']?['email'] ?? email;
        }
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'auth_signup',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Sign up successful: $_userEmail');
        return true;
      } else {
        print('[SupabaseService] ❌ Sign up failed: ${response.statusCode}');
        print('[SupabaseService] Response: ${response.body}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'auth_signup',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Sign up error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'auth_signup',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  /// Sign in existing user
  Future<bool> signIn(String email, String password) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': _supabaseKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token'] ?? '';
        _userId = data['user']?['id'] ?? '';
        _userEmail = data['user']?['email'] ?? email;
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'auth_signin',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Sign in successful: $_userEmail');
        print('[SupabaseService] 👤 User ID: $_userId');
        return true;
      } else {
        print('[SupabaseService] ❌ Sign in failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'auth_signin',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Sign in error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'auth_signin',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/logout'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('[SupabaseService] Sign out error (ignored): $e');
    }
    
    _authToken = '';
    _userId = '';
    _userEmail = '';
    print('[SupabaseService] ✅ Signed out');
  }
  
  // ============ BOOKING CRUD ============
  
  /// Insert new booking dengan notes & photos support
  Future<String?> insertBooking(HiveBooking booking) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated, skipping insert');
      return null;
    }
    
    // Prepare booking data dengan notes dan photoUrls
    final bookingData = {
      'id': booking.id,
      'customer_name': booking.customerName,
      'phone_number': booking.phoneNumber,
      'service_name': booking.serviceName,
      'latitude': booking.latitude,
      'longitude': booking.longitude,
      'address': booking.address,
      'booking_date': booking.bookingDate.toIso8601String(),
      'booking_time': booking.bookingTime,
      'total_price': booking.totalPrice,
      'status': booking.status,
      'notes': booking.notes,
      'photo_urls': booking.photoUrls ?? [],
      'created_at': booking.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'user_id': _userId,
    };
    
    print('[SupabaseService] 📤 Attempting to insert booking:');
    print('[SupabaseService]    ID: ${booking.id}');
    print('[SupabaseService]    Customer: ${booking.customerName}');
    print('[SupabaseService]    Service: ${booking.serviceName}');
    print('[SupabaseService]    Notes: ${booking.notes}');
    print('[SupabaseService]    Photos: ${booking.photoUrls?.length ?? 0}');
    print('[SupabaseService]    User ID: $_userId');
    
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_apiPath/bookings'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(bookingData),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      print('[SupabaseService] 📥 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final insertedId = data.isNotEmpty ? data[0]['id'] as String : booking.id;
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_insert_${booking.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Booking inserted successfully: $insertedId');
        print('[SupabaseService] ⏱️ Execution time: ${stopwatch.elapsedMilliseconds}ms');
        return insertedId;
      } else {
        print('[SupabaseService] ❌ Insert failed with status: ${response.statusCode}');
        print('[SupabaseService] ❌ Error body: ${response.body}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_insert_${booking.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode} - ${response.body}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Insert exception: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'booking_insert_${booking.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Get all bookings
  Future<List<Map<String, dynamic>>> getBookings() async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl$_apiPath/bookings?order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final bookings = data.map((e) => e as Map<String, dynamic>).toList();
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'all_bookings',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Fetched ${bookings.length} bookings');
        return bookings;
      } else {
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'all_bookings',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return [];
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Fetch error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'supabase',
        dataKey: 'all_bookings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Update booking photos URLs
  Future<bool> updateBookingPhotos(String bookingId, List<String> photoUrls) async {
    if (!isAuthenticated) return false;
    
    try {
      final response = await http.patch(
        Uri.parse('$_supabaseUrl$_apiPath/bookings?id=eq.$bookingId'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'photo_urls': photoUrls,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('[SupabaseService] ✅ Booking photos updated: $bookingId');
        return true;
      }
      return false;
    } catch (e) {
      print('[SupabaseService] ❌ Update photos error: $e');
      return false;
    }
  }
  
  /// Update booking status
  Future<bool> updateBookingStatus(String id, String newStatus) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }
    
    try {
      final response = await http.patch(
        Uri.parse('$_supabaseUrl$_apiPath/bookings?id=eq.$id'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_update_$id',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Booking status updated: $id -> $newStatus');
        return true;
      } else {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_update_$id',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'booking_update_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  /// Delete booking
  Future<bool> deleteBooking(String id) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }
    
    try {
      final response = await http.delete(
        Uri.parse('$_supabaseUrl$_apiPath/bookings?id=eq.$id'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_delete_$id',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Booking deleted: $id');
        return true;
      } else {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_delete_$id',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'booking_delete_$id',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  // ============ NOTES CRUD ============
  
  /// Create new note
  Future<String?> createNote(String title, String content, String userId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return null;
    }
    
    // Verify user owns this note
    if (userId != _userId) {
      print('[SupabaseService] ❌ User ID mismatch - not authorized');
      return null;
    }
    
    try {
      final noteData = {
        'user_id': _userId,
        'title': title,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': true,
      };
      
      print('[SupabaseService] 📝 Creating note...');
      print('[SupabaseService]    Title: $title');
      print('[SupabaseService]    User: $_userId');
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_apiPath/notes'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(noteData),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final noteId = data.isNotEmpty ? data[0]['id'] as String : '';
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_create',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note created: $noteId');
        return noteId;
      } else {
        print('[SupabaseService] ❌ Create failed: ${response.statusCode}');
        print('[SupabaseService] Response: ${response.body}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_create',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Create error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_create',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Update note
  Future<bool> updateNote(String noteId, String title, String content) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }
    
    try {
      print('[SupabaseService] 📝 Updating note: $noteId');
      
      final response = await http.patch(
        Uri.parse('$_supabaseUrl$_apiPath/notes?id=eq.$noteId&user_id=eq.$_userId'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_update_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note updated: $noteId');
        return true;
      } else {
        print('[SupabaseService] ❌ Update failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_update_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Update error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_update_$noteId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  /// Get all user's notes
  Future<List<Map<String, dynamic>>> getUserNotes() async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }
    
    try {
      print('[SupabaseService] 📖 Fetching user notes...');
      
      final response = await http.get(
        Uri.parse('$_supabaseUrl$_apiPath/notes?user_id=eq.$_userId&order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final notes = data.map((e) => e as Map<String, dynamic>).toList();
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'user_notes',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Fetched ${notes.length} notes');
        return notes;
      } else {
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'user_notes',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return [];
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Fetch error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'supabase',
        dataKey: 'user_notes',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Delete note with verification
  Future<bool> deleteNoteSecure(String noteId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }
    
    try {
      print('[SupabaseService] 🗑️ Deleting note: $noteId');
      
      final response = await http.delete(
        Uri.parse('$_supabaseUrl$_apiPath/notes?id=eq.$noteId&user_id=eq.$_userId'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_delete_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note deleted: $noteId');
        return true;
      } else {
        print('[SupabaseService] ❌ Delete failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_delete_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Delete error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_delete_$noteId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  /// Upload image for note
  Future<String?> uploadNoteImage(File imageFile, String noteId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return null;
    }
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'notes/$_userId/$noteId/${timestamp}_image.$extension';
      
      final bytes = await imageFile.readAsBytes();
      
      print('[SupabaseService] 📸 Uploading note image: $fileName');
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_storagePath/object/note-images/$fileName'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'image/$extension',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final publicUrl = '$_supabaseUrl$_storagePath/object/public/note-images/$fileName';
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_image_upload',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Image uploaded: $publicUrl');
        return publicUrl;
      } else {
        print('[SupabaseService] ❌ Upload failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_image_upload',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Upload error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_image_upload',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Insert or update note
  Future<String?> insertOrUpdateNote(HiveNote note) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated, skipping note insert');
      return null;
    }
    
    try {
      final noteData = {
        'id': note.supabaseId ?? note.id,
        'title': note.title,
        'content': note.content,
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'user_id': _userId,
      };
      
      print('[SupabaseService] 📝 Creating or updating note...');
      print('[SupabaseService]    Title: ${note.title}');
      print('[SupabaseService]    User: $_userId');
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_apiPath/notes'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(noteData),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final noteId = data.isNotEmpty ? data[0]['id'] as String : note.id;
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_insert_${note.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note inserted: $noteId');
        return noteId;
      } else {
        print('[SupabaseService] ❌ Insert failed: ${response.statusCode}');
        print('[SupabaseService] Response: ${response.body}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_insert_${note.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Insert exception: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_insert_${note.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Get notes for booking
  Future<List<Map<String, dynamic>>> getNotesByBookingId(String bookingId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl$_apiPath/notes?booking_id=eq.$bookingId&order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final notes = data.map((e) => e as Map<String, dynamic>).toList();
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'notes_booking_$bookingId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Fetched ${notes.length} notes');
        return notes;
      } else {
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'notes_booking_$bookingId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return [];
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Fetch error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'supabase',
        dataKey: 'notes_booking_$bookingId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Get all notes for user (standalone)
  Future<List<Map<String, dynamic>>> getNotesByUserId(String userId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }
    
    try {
      print('[SupabaseService] 📖 Fetching user notes...');
      
      final response = await http.get(
        Uri.parse('$_supabaseUrl$_apiPath/notes?user_id=eq.$userId&order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final notes = data.map((e) => e as Map<String, dynamic>).toList();
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'notes_user_$userId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Fetched ${notes.length} notes for user');
        return notes;
      } else {
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'notes_user_$userId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return [];
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Fetch error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'supabase',
        dataKey: 'notes_user_$userId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
  
  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }
    
    try {
      print('[SupabaseService] 🗑️ Deleting note: $noteId');
      
      final response = await http.delete(
        Uri.parse('$_supabaseUrl$_apiPath/notes?id=eq.$noteId'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_delete_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note deleted: $noteId');
        return true;
      } else {
        print('[SupabaseService] ❌ Delete failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_delete_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Delete error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_delete_$noteId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }
  
  // ============ STORAGE: File Upload ============
  
  /// Upload photo to Supabase Storage
  Future<String?> uploadPhoto(File photoFile, String bookingId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return null;
    }
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = photoFile.path.split('.').last;
      final fileName = '$bookingId/${timestamp}_photo.$extension';
      
      final bytes = await photoFile.readAsBytes();
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_storagePath/object/booking-photos/$fileName'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'image/$extension',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final publicUrl = '$_supabaseUrl$_storagePath/object/public/booking-photos/$fileName';
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'photo_upload_$bookingId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Photo uploaded: $publicUrl');
        return publicUrl;
      } else {
        print('[SupabaseService] ❌ Upload failed: ${response.statusCode}');
        print('[SupabaseService] Response: ${response.body}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'photo_upload_$bookingId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Upload error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'photo_upload_$bookingId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Upload photo for notes
  Future<String?> uploadNotePhoto(File photoFile, String noteId) async {
    final stopwatch = Stopwatch()..start();
    
    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return null;
    }
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = photoFile.path.split('.').last;
      final fileName = 'notes/$noteId/${timestamp}_photo.$extension';
      
      final bytes = await photoFile.readAsBytes();
      
      print('[SupabaseService] 📸 Uploading note photo: $fileName');
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl$_storagePath/object/note-photos/$fileName'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'image/$extension',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final publicUrl = '$_supabaseUrl$_storagePath/object/public/note-photos/$fileName';
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_photo_upload_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        print('[SupabaseService] ✅ Note photo uploaded: $publicUrl');
        return publicUrl;
      } else {
        print('[SupabaseService] ❌ Upload failed: ${response.statusCode}');
        
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'note_photo_upload_$noteId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: false,
          errorMessage: 'Status: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Upload error: $e');
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'write',
        storageType: 'supabase',
        dataKey: 'note_photo_upload_$noteId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
  
  /// Delete photo from Storage
  Future<bool> deletePhoto(String photoUrl) async {
    if (!isAuthenticated) return false;
    
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final fileIndex = pathSegments.indexOf('public') + 2;
      final filePath = pathSegments.sublist(fileIndex).join('/');
      
      final response = await http.delete(
        Uri.parse('$_supabaseUrl$_storagePath/object/booking-photos/$filePath'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        print('[SupabaseService] ✅ Photo deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('[SupabaseService] ❌ Delete photo error: $e');
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getNotesWithFilter({
  String? userId,
  String? searchQuery,
  DateTime? startDate,
  DateTime? endDate,
  int? limit,
}) async {
  final stopwatch = Stopwatch()..start();
  
  if (!isAuthenticated) {
    print('[SupabaseService] ⚠️ Not authenticated');
    return [];
  }
  
  try {
    String url = '$_supabaseUrl$_apiPath/notes?';
    List<String> params = [];
    
    // Build query parameters
    if (userId != null) {
      params.add('user_id=eq.$userId');
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      params.add('or=(title.ilike.%$searchQuery%,content.ilike.%$searchQuery%)');
    }
    
    if (startDate != null) {
      params.add('created_at=gte.${startDate.toIso8601String()}');
    }
    
    if (endDate != null) {
      params.add('created_at=lte.${endDate.toIso8601String()}');
    }
    
    // Always order by creation date
    params.add('order=created_at.desc');
    
    if (limit != null) {
      params.add('limit=$limit');
    }
    
    url += params.join('&');
    
    print('[SupabaseService] 🔍 Executing filtered query: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_authToken',
      },
    ).timeout(const Duration(seconds: 15));
    
    stopwatch.stop();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final notes = data.map((e) => e as Map<String, dynamic>).toList();
      
      _tracker.addLog(StoragePerformanceLog(
        operation: 'read',
        storageType: 'supabase',
        dataKey: 'notes_filtered',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      print('[SupabaseService] ✅ Filtered query completed: ${notes.length} notes');
      return notes;
    } else {
      print('[SupabaseService] ❌ Filtered query failed: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    stopwatch.stop();
    print('[SupabaseService] ❌ Filtered query error: $e');
    return [];
  }
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