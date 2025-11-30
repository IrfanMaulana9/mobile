import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';

/// Controller untuk manage theme dengan SharedPreferences
class ThemeController extends GetxController {
  late StorageController storageController;
  
  final themeMode = ThemeMode.system.obs;
  final isDark = false.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      storageController = Get.find<StorageController>();
      
      // Wait for initialization
      if (!storageController.isInitialized.value) {
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Load saved theme
      await loadTheme();
      
      print('[ThemeController] ✅ Initialized with theme: ${themeMode.value}');
    } catch (e) {
      print('[ThemeController] ❌ Initialization error: $e');
    }
  }
  
  /// Load theme from SharedPreferences
  Future<void> loadTheme() async {
    try {
      final savedTheme = storageController.getTheme();
      
      switch (savedTheme) {
        case 'light':
          themeMode.value = ThemeMode.light;
          isDark.value = false;
          break;
        case 'dark':
          themeMode.value = ThemeMode.dark;
          isDark.value = true;
          break;
        case 'system':
        default:
          themeMode.value = ThemeMode.system;
          isDark.value = Get.isPlatformDarkMode;
          break;
      }
      
      print('[ThemeController] 📱 Theme loaded: $savedTheme');
    } catch (e) {
      print('[ThemeController] ❌ Load theme error: $e');
    }
  }
  
  /// Set theme and save to SharedPreferences
  Future<void> setTheme(ThemeMode mode) async {
    try {
      themeMode.value = mode;
      
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          isDark.value = false;
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          isDark.value = true;
          break;
        case ThemeMode.system:
          themeString = 'system';
          isDark.value = Get.isPlatformDarkMode;
          break;
      }
      
      await storageController.setTheme(themeString);
      
      // Update GetX theme
      Get.changeThemeMode(mode);
      
      print('[ThemeController] ✅ Theme changed to: $themeString');
      
      Get.snackbar(
        'Theme Updated',
        'Theme changed to ${themeString}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('[ThemeController] ❌ Set theme error: $e');
    }
  }
  
  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    if (themeMode.value == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }
  
  /// Quick setters
  Future<void> setLightTheme() async => await setTheme(ThemeMode.light);
  Future<void> setDarkTheme() async => await setTheme(ThemeMode.dark);
  Future<void> setSystemTheme() async => await setTheme(ThemeMode.system);
}