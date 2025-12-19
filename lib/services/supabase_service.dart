import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Added shared_preferences untuk menyimpan session
import '../models/hive_models.dart';
import '../models/storage_performance.dart';
import '../models/payment.dart';
import 'hive_service.dart';

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
      _supabaseKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmFxdnlqeGxxdW9xaGduaXFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyOTQwNjIsImV4cCI6MjA3ODg3MDA2Mn0.NFDTQlg0hIIaoLg_6TbVth1-nXBBE7BEIp9-206EjMQ';

      if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
        throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
      }

      await _loadSavedSession();

      print('[SupabaseService] ✅ Initialized with hardcoded credentials');
      print('[SupabaseService] 📍 URL: $_supabaseUrl');
      if (isAuthenticated) {
        print('[SupabaseService] 🔐 Session restored: $_userEmail');
      }
    } catch (e) {
      print('[SupabaseService] ❌ Initialization error: $e');
      rethrow;
    }
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('supabase_auth_token');
      final savedUserId = prefs.getString('supabase_user_id');
      final savedEmail = prefs.getString('supabase_user_email');

      if (savedToken != null && savedUserId != null && savedEmail != null) {
        _authToken = savedToken;
        _userId = savedUserId;
        _userEmail = savedEmail;
        print('[SupabaseService] ✅ Session restored from storage');
      }
    } catch (e) {
      print('[SupabaseService] ⚠️ Failed to load session: $e');
    }
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_auth_token', _authToken);
      await prefs.setString('supabase_user_id', _userId);
      await prefs.setString('supabase_user_email', _userEmail);
      print('[SupabaseService] ✅ Session saved to storage');
    } catch (e) {
      print('[SupabaseService] ⚠️ Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('supabase_auth_token');
      await prefs.remove('supabase_user_id');
      await prefs.remove('supabase_user_email');
      print('[SupabaseService] ✅ Session cleared from storage');
    } catch (e) {
      print('[SupabaseService] ⚠️ Failed to clear session: $e');
    }
  }

  // ============ AUTHENTICATION ============

  /// Sign up new user
  Future<bool> signUp(String email, String password) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .post(
            Uri.parse('$_supabaseUrl/auth/v1/signup'),
            headers: {
              'apikey': _supabaseKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

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

        await _saveSession();

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
      final response = await http
          .post(
            Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
            headers: {
              'apikey': _supabaseKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token'] ?? '';
        _userId = data['user']?['id'] ?? '';
        _userEmail = data['user']?['email'] ?? email;

        await _saveSession();

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

    await _clearSession();

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
      final response = await http
          .post(
            Uri.parse('$_supabaseUrl$_apiPath/bookings'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(bookingData),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      print('[SupabaseService] 📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final insertedId =
            data.isNotEmpty ? data[0]['id'] as String : booking.id;

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'booking_insert_${booking.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Booking inserted successfully: $insertedId');
        print(
            '[SupabaseService] ⏱️ Execution time: ${stopwatch.elapsedMilliseconds}ms');
        return insertedId;
      } else {
        print(
            '[SupabaseService] ❌ Insert failed with status: ${response.statusCode}');
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
        // Filter by current user so multi-device works per-account
        Uri.parse(
            '$_supabaseUrl$_apiPath/bookings?user_id=eq.$_userId&order=created_at.desc'),
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
  Future<bool> updateBookingPhotos(
      String bookingId, List<String> photoUrls) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .patch(
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
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await http
          .patch(
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
          )
          .timeout(const Duration(seconds: 15));

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
  Future<String?> createNote(
      String title, String content, String userId) async {
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

      final response = await http
          .post(
            Uri.parse('$_supabaseUrl$_apiPath/notes'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(noteData),
          )
          .timeout(const Duration(seconds: 15));

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

      final response = await http
          .patch(
            Uri.parse(
                '$_supabaseUrl$_apiPath/notes?id=eq.$noteId&user_id=eq.$_userId'),
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
          )
          .timeout(const Duration(seconds: 15));

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
        Uri.parse(
            '$_supabaseUrl$_apiPath/notes?user_id=eq.$_userId&order=created_at.desc'),
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
        Uri.parse(
            '$_supabaseUrl$_apiPath/notes?id=eq.$noteId&user_id=eq.$_userId'),
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

      final response = await http
          .post(
            Uri.parse(
                '$_supabaseUrl$_storagePath/object/note-images/$fileName'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'image/$extension',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final publicUrl =
            '$_supabaseUrl$_storagePath/object/public/note-images/$fileName';

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

      final response = await http
          .post(
            Uri.parse('$_supabaseUrl$_apiPath/notes'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(noteData),
          )
          .timeout(const Duration(seconds: 15));

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
  Future<List<Map<String, dynamic>>> getNotesByBookingId(
      String bookingId) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_supabaseUrl$_apiPath/notes?booking_id=eq.$bookingId&order=created_at.desc'),
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
        Uri.parse(
            '$_supabaseUrl$_apiPath/notes?user_id=eq.$userId&order=created_at.desc'),
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

      final response = await http
          .post(
            Uri.parse(
                '$_supabaseUrl$_storagePath/object/booking-photos/$fileName'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'image/$extension',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final publicUrl =
            '$_supabaseUrl$_storagePath/object/public/booking-photos/$fileName';

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

      final response = await http
          .post(
            Uri.parse(
                '$_supabaseUrl$_storagePath/object/note-photos/$fileName'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'image/$extension',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final publicUrl =
            '$_supabaseUrl$_storagePath/object/public/note-photos/$fileName';

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
  // ============ RATING REVIEW CRUD ============

  /// Insert rating review
  Future<String?> insertRatingReview({
    required String bookingId,
    required String userId,
    required String customerName,
    required String serviceName,
    required int rating,
    required String review,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print(
          '[SupabaseService] ⚠️ Not authenticated, skipping rating review insert');
      return null;
    }

    try {
      final ratingData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'booking_id': bookingId,
        'user_id': userId,
        'customer_name': customerName,
        'service_name': serviceName,
        'rating': rating,
        'review': review,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('[SupabaseService] ⭐ Creating rating review...');
      print('[SupabaseService]    Booking: $bookingId');
      print('[SupabaseService]    Rating: $rating stars');
      print('[SupabaseService]    User: $userId');

      final response = await http
          .post(
            Uri.parse('$_supabaseUrl$_apiPath/rating_reviews'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(ratingData),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final ratingId = data.isNotEmpty
            ? (data[0] as Map<String, dynamic>)['id'] as String
            : ratingData['id'] as String;

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'rating_insert_${ratingData['id']}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Rating review inserted: $ratingId');
        return ratingId;
      } else {
        final responseBody = response.body;
        print('[SupabaseService] ❌ Insert failed: ${response.statusCode}');
        print('[SupabaseService] Response: $responseBody');

        // Check if table doesn't exist (404 error) - fallback to Hive
        if (response.statusCode == 404) {
          try {
            final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
            final message = errorData['message'] as String? ?? '';
            if (message.contains('Could not find the table') || 
                message.contains('rating_reviews')) {
              print('[SupabaseService] ⚠️ Table "rating_reviews" does not exist in Supabase');
              print('[SupabaseService] 💡 Saving to local storage (Hive) as fallback');
              
              // Fallback to Hive
              try {
                final hiveService = HiveService();
                final hiveRating = HiveRatingReview(
                  id: ratingData['id'] as String,
                  bookingId: bookingId,
                  userId: userId,
                  customerName: customerName,
                  serviceName: serviceName,
                  rating: rating,
                  review: review,
                  createdAt: DateTime.parse(ratingData['created_at'] as String),
                  updatedAt: DateTime.parse(ratingData['updated_at'] as String),
                  synced: false,
                );
                await hiveService.addRatingReview(hiveRating);
                print('[SupabaseService] ✅ Rating review saved to local storage');
                return ratingData['id'] as String;
              } catch (e) {
                print('[SupabaseService] ❌ Failed to save to Hive: $e');
              }
            }
          } catch (e) {
            // Ignore JSON parse errors
          }
        }

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'rating_insert_${ratingData['id']}',
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
        dataKey: 'rating_insert_$bookingId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }

  /// Get all rating reviews (for public display)
  Future<List<Map<String, dynamic>>> getAllRatingReviews() async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }

    try {
      print('[SupabaseService] ⭐ Fetching all rating reviews...');

      final response = await http.get(
        Uri.parse(
            '$_supabaseUrl$_apiPath/rating_reviews?order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final ratings = data.map((e) => e as Map<String, dynamic>).toList();

        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'all_ratings',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Fetched ${ratings.length} rating reviews');
        return ratings;
      } else {
        final responseBody = response.body;
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        
        // Check if table doesn't exist (404 error) - fallback to Hive
        if (response.statusCode == 404) {
          try {
            final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
            final message = errorData['message'] as String? ?? '';
            if (message.contains('Could not find the table') || 
                message.contains('rating_reviews')) {
              print('[SupabaseService] ⚠️ Table "rating_reviews" does not exist in Supabase');
              print('[SupabaseService] 💡 Loading from local storage (Hive) as fallback');
              
              // Fallback to Hive
              try {
                final hiveService = HiveService();
                final hiveRatings = hiveService.getAllRatingReviews();
                final ratings = hiveRatings.map((r) => r.toRatingReviewMap()).toList();
                print('[SupabaseService] ✅ Loaded ${ratings.length} rating reviews from local storage');
                return ratings;
              } catch (e) {
                print('[SupabaseService] ❌ Failed to load from Hive: $e');
              }
            }
          } catch (e) {
            // Ignore JSON parse errors
          }
        }

        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'all_ratings',
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
        dataKey: 'all_ratings',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }

  /// Delete rating review
  Future<bool> deleteRatingReview(String ratingId) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }

    try {
      print('[SupabaseService] 🗑️ Deleting rating review: $ratingId');

      final response = await http.delete(
        Uri.parse('$_supabaseUrl$_apiPath/rating_reviews?id=eq.$ratingId'),
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
          dataKey: 'rating_delete_$ratingId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Rating review deleted: $ratingId');
        return true;
      } else {
        final responseBody = response.body;
        print('[SupabaseService] ❌ Delete failed: ${response.statusCode}');
        
        // Check if table doesn't exist (404 error)
        if (response.statusCode == 404) {
          try {
            final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
            final message = errorData['message'] as String? ?? '';
            if (message.contains('Could not find the table') || 
                message.contains('rating_reviews')) {
              print('[SupabaseService] ⚠️ Table "rating_reviews" does not exist in Supabase');
              print('[SupabaseService] 💡 Delete operation skipped');
            }
          } catch (e) {
            // Ignore JSON parse errors
          }
        }

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'rating_delete_$ratingId',
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
        dataKey: 'rating_delete_$ratingId',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return false;
    }
  }

  // ============ PAYMENT CRUD ============

  /// Insert payment
  Future<Payment?> insertPayment(Payment payment) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated, skipping payment insert');
      return null;
    }

    try {
      final paymentData = payment.toMap();

      print('[SupabaseService] 💳 Inserting payment...');
      print('[SupabaseService]    ID: ${payment.id}');
      print('[SupabaseService]    Booking: ${payment.bookingId}');
      print('[SupabaseService]    Amount: ${payment.amount}');
      print('[SupabaseService]    Method: ${payment.paymentMethod.displayName}');

      final response = await http
          .post(
            Uri.parse('$_supabaseUrl$_apiPath/payments'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(paymentData),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final paymentMap = data.isNotEmpty
            ? data[0] as Map<String, dynamic>
            : paymentData;

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'payment_insert_${payment.id}',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Payment inserted: ${payment.id}');
        return Payment.fromMap(paymentMap);
      } else {
        final responseBody = response.body;
        print('[SupabaseService] ❌ Insert failed: ${response.statusCode}');
        print('[SupabaseService] Response: $responseBody');

        // Check if table doesn't exist (404 error) - fallback to Hive
        if (response.statusCode == 404) {
          print('[SupabaseService] ⚠️ Table "payments" does not exist');
          print('[SupabaseService] 💡 Please create the table in Supabase');
        }

        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'payment_insert_${payment.id}',
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
        dataKey: 'payment_insert_${payment.id}',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return [];
    }

    try {
      print('[SupabaseService] 💳 Fetching payment history...');

      final response = await http.get(
        Uri.parse(
            '$_supabaseUrl$_apiPath/payments?user_id=eq.$_userId&order=created_at.desc'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final payments = data.map((e) => e as Map<String, dynamic>).toList();

        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'payment_history',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Fetched ${payments.length} payments');
        return payments;
      } else {
        final responseBody = response.body;
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');

        // Check if table doesn't exist (404 error)
        if (response.statusCode == 404) {
          try {
            final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
            final message = errorData['message'] as String? ?? '';
            if (message.contains('Could not find the table') ||
                message.contains('payments')) {
              print('[SupabaseService] ⚠️ Table "payments" does not exist');
              print('[SupabaseService] 💡 Returning empty list');
            }
          } catch (e) {
            // Ignore JSON parse errors
          }
        }

        _tracker.addLog(StoragePerformanceLog(
          operation: 'read',
          storageType: 'supabase',
          dataKey: 'payment_history',
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
        dataKey: 'payment_history',
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }

  /// Get payment by booking ID
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return null;
    }

    try {
      print('[SupabaseService] 💳 Fetching payment for booking: $bookingId');

      final response = await http.get(
        Uri.parse(
            '$_supabaseUrl$_apiPath/payments?booking_id=eq.$bookingId&order=created_at.desc&limit=1'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final paymentMap = data[0] as Map<String, dynamic>;
          print('[SupabaseService] ✅ Payment found for booking');
          return Payment.fromMap(paymentMap);
        }
        return null;
      } else {
        print('[SupabaseService] ❌ Fetch failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Fetch error: $e');
      return null;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    DateTime? paidAt,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (!isAuthenticated) {
      print('[SupabaseService] ⚠️ Not authenticated');
      return false;
    }

    try {
      print('[SupabaseService] 💳 Updating payment status: $paymentId -> ${status.value}');

      final updateData = <String, dynamic>{
        'status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paidAt != null) {
        updateData['paid_at'] = paidAt.toIso8601String();
      }

      final response = await http
          .patch(
            Uri.parse('$_supabaseUrl$_apiPath/payments?id=eq.$paymentId'),
            headers: {
              'apikey': _supabaseKey,
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      if (response.statusCode == 200 || response.statusCode == 204) {
        _tracker.addLog(StoragePerformanceLog(
          operation: 'write',
          storageType: 'supabase',
          dataKey: 'payment_update_$paymentId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
          success: true,
          timestamp: DateTime.now(),
        ));

        print('[SupabaseService] ✅ Payment status updated');
        return true;
      } else {
        print('[SupabaseService] ❌ Update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      print('[SupabaseService] ❌ Update error: $e');
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
        params.add(
            'or=(title.ilike.%$searchQuery%,content.ilike.%$searchQuery%)');
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

        print(
            '[SupabaseService] ✅ Filtered query completed: ${notes.length} notes');
        return notes;
      } else {
        print(
            '[SupabaseService] ❌ Filtered query failed: ${response.statusCode}');
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
