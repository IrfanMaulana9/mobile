import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  static const String routeName = '/auth';
  
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final controller = Get.put(AuthController());
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or Icon
            Icon(
              Icons.cleaning_services,
              size: 80,
              color: cs.primary,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Layanan Kebersihan Kos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Password Field
            Obx(() => TextField(
              controller: _passwordController,
              obscureText: controller.obscurePassword.value,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )),
            
            // Confirm Password (Register only)
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              Obx(() => TextField(
                controller: _confirmPasswordController,
                obscureText: controller.obscurePassword.value,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )),
            ],
            
            const SizedBox(height: 24),
            
            // Login/Register Button
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => _handleAuth(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Login' : 'Register'),
            )),
            
            const SizedBox(height: 16),
            
            // Toggle Login/Register
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _confirmPasswordController.clear();
                });
              },
              child: Text(
                _isLogin
                    ? 'Belum punya akun? Register'
                    : 'Sudah punya akun? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Email dan password harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }
    
    if (!_isLogin) {
      // Validate confirm password for registration
      final confirmPassword = _confirmPasswordController.text.trim();
      if (password != confirmPassword) {
        Get.snackbar(
          'Error',
          'Password tidak cocok',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        return;
      }
      
      if (password.length < 6) {
        Get.snackbar(
          'Error',
          'Password minimal 6 karakter',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        return;
      }
    }
    
    bool success;
    if (_isLogin) {
      success = await controller.signIn(email, password);
    } else {
      success = await controller.signUp(email, password);
    }
    
    if (success) {
      Get.offAllNamed('/');
    }
  }
}