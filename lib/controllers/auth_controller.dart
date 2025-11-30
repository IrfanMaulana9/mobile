import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../controllers/storage_controller.dart';

/// Controller untuk Authentication dengan Supabase - PURE LOGIN/REGISTER
class AuthController extends GetxController {
  final supabaseService = SupabaseService();
  late StorageController storageController;
  
  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final obscurePassword = true.obs;
  final userEmail = ''.obs;
  final userId = ''.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      // Get storage controller
      storageController = Get.find<StorageController>();
      
      // Check if already authenticated
      isAuthenticated.value = supabaseService.isAuthenticated;
      if (isAuthenticated.value) {
        userEmail.value = supabaseService.userEmail;
        userId.value = supabaseService.userId;
      }
      
      print('[AuthController] ✅ Initialized - Pure Auth Mode');
      print('[AuthController] Authenticated: ${isAuthenticated.value}');
      if (isAuthenticated.value) {
        print('[AuthController] User: ${userEmail.value}');
      }
    } catch (e) {
      print('[AuthController] ❌ Initialization error: $e');
    }
  }
  
  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  /// Sign up new user
  Future<bool> signUp(String email, String password) async {
    isLoading.value = true;
    
    try {
      print('[AuthController] 📝 Attempting sign up: $email');
      
      final success = await supabaseService.signUp(email, password);
      
      if (success) {
        isAuthenticated.value = true;
        userEmail.value = email;
        userId.value = supabaseService.userId;
        
        Get.snackbar(
          'Success',
          'Akun berhasil dibuat!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 3),
        );
        
        print('[AuthController] ✅ Sign up successful: $email');
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Gagal membuat akun. Email mungkin sudah terdaftar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 3),
        );
        
        print('[AuthController] ❌ Sign up failed');
        return false;
      }
    } catch (e) {
      print('[AuthController] ❌ Sign up error: $e');
      
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 3),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Sign in existing user
  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    
    try {
      print('[AuthController] 🔐 Attempting sign in: $email');
      
      final success = await supabaseService.signIn(email, password);
      
      if (success) {
        isAuthenticated.value = true;
        userEmail.value = email;
        userId.value = supabaseService.userId;
        
        Get.snackbar(
          'Success',
          'Login berhasil!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 3),
        );
        
        // Trigger sync after login
        try {
          await storageController.syncNow();
          print('[AuthController] ✅ Auto-sync triggered after login');
        } catch (e) {
          print('[AuthController] ⚠️ Auto-sync failed: $e');
        }
        
        print('[AuthController] ✅ Sign in successful: $email');
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Email atau password salah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 3),
        );
        
        print('[AuthController] ❌ Sign in failed: wrong credentials');
        return false;
      }
    } catch (e) {
      print('[AuthController] ❌ Sign in error: $e');
      
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 3),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      print('[AuthController] 🚪 Signing out...');
      
      await supabaseService.signOut();
      
      isAuthenticated.value = false;
      userEmail.value = '';
      userId.value = '';
      
      Get.snackbar(
        'Success',
        'Logout berhasil',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        duration: const Duration(seconds: 2),
      );
      
      print('[AuthController] ✅ Signed out successfully');
      
      // Navigate to auth page
      Get.offAllNamed('/auth');
    } catch (e) {
      print('[AuthController] ❌ Sign out error: $e');
      
      // Force reset even if error
      isAuthenticated.value = false;
      userEmail.value = '';
      userId.value = '';
    }
  }
  
  /// Check if user is authenticated
  bool get isUserAuthenticated => isAuthenticated.value;
  
  /// Get current user email
  String get currentUserEmail => userEmail.value;
  
  /// Get current user ID
  String get currentUserId => userId.value;
}