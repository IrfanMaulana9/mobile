import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// Middleware to protect routes - requires authentication
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // If not authenticated, redirect to auth page
    if (!authController.isAuthenticated.value) {
      print('[AuthMiddleware] ⚠️ Not authenticated, redirecting to /auth');
      return const RouteSettings(name: '/auth');
    }
    
    print('[AuthMiddleware] ✅ Authenticated, allowing access to $route');
    return null; // Allow access
  }
}