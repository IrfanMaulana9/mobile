import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'controllers/storage_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/gps_controller.dart';
import 'controllers/network_location_controller.dart';
import 'controllers/experiment_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/rating_review_controller.dart';
import 'pages/splash_screen.dart';
import 'pages/home_page.dart';
import 'pages/weather_demo.dart';
import 'pages/booking_page.dart';
import 'pages/booking_history_page.dart';
import 'pages/storage_stats_page.dart';
import 'pages/performance_stats_page.dart';
import 'pages/auth_page.dart';
import 'pages/rating_review_page.dart';
import 'pages/promo_page.dart';
import 'pages/notifications_page.dart';
import 'pages/payment_page.dart';
import 'pages/payment_history_page.dart';
import 'pages/invoice_page.dart';
import 'controllers/payment_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('[v0] Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[v0] Firebase initialized successfully');
    
    print('[v0] Initializing Notification Service...');
    try {
      await NotificationService().initialize();
      print('[v0] Notification Service initialized');
    } catch (e) {
      print('[v0] Notification Service initialization failed: $e');
      print('[v0] Continuing without push notifications...');
    }
    
    await Hive.initFlutter();
    
    final storageController = StorageController();
    Get.put(storageController);
    await storageController.onInit();
    
    final themeController = ThemeController();
    Get.put(themeController);
    await themeController.onInit();
    
    final authController = AuthController();
    Get.put(authController);
    await authController.onInit();
    
    final bookingController = BookingController();
    Get.put(bookingController);
    
    final gpsController = GPSController();
    Get.put(gpsController);
    
    final networkLocationController = NetworkLocationController();
    Get.put(networkLocationController);
    
    final experimentController = ExperimentController();
    Get.put(experimentController);
    
    final notificationController = NotificationController();
    Get.put(notificationController);
    
    final ratingReviewController = RatingReviewController();
    Get.put(ratingReviewController);
    
    final paymentController = PaymentController();
    Get.put(paymentController);
    
    runApp(CleaningServiceApp());
  } catch (e, stackTrace) {
    print('[v0] Fatal error during initialization: $e');
    print('[v0] Stack trace: $stackTrace');
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check:\n1. Internet connection\n2. Firebase Console setup\n3. google-services.json file',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class CleaningServiceApp extends StatelessWidget {
  CleaningServiceApp({super.key});

  final themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0052A5),
      brightness: Brightness.light,
      surface: const Color(0xFFFBFBFB),
      primary: const Color(0xFF1AA5D4),
      secondary: const Color(0xFFFF9C42),
    );
    
    final dark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0052A5),
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
      primary: const Color(0xFF00D9FF),
      secondary: const Color(0xFFFF9C42),
    );

    return Obx(() => GetMaterialApp(
      title: 'CleanServ - Layanan Kebersihan',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        colorScheme: light,
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: light.primary,
          foregroundColor: light.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: light.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: light.primary,
            foregroundColor: light.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      
      darkTheme: ThemeData(
        colorScheme: dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: dark.primary,
          foregroundColor: dark.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: dark.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: dark.primary,
            foregroundColor: dark.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      
      themeMode: themeController.themeMode.value,
      
      initialRoute: '/splash',
      
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/',
          page: () => HomePage(
            isDark: themeController.isDark.value,
            onChangeTheme: (isDark) {
              themeController.setTheme(
                isDark ? ThemeMode.dark : ThemeMode.light
              );
            },
          ),
        ),
        GetPage(
          name: WeatherDemoPage.routeName,
          page: () => const WeatherDemoPage(),
        ),
        GetPage(
          name: BookingPage.routeName,
          page: () => const BookingPage(),
        ),
        GetPage(
          name: BookingHistoryPage.routeName,
          page: () => const BookingHistoryPage(),
        ),
        GetPage(
          name: StorageStatsPage.routeName,
          page: () => const StorageStatsPage(),
        ),
        GetPage(
          name: PerformanceStatsPage.routeName,
          page: () => const PerformanceStatsPage(),
        ),
        GetPage(
          name: '/auth',
          page: () => const AuthPage(),
        ),
        GetPage(
          name: RatingReviewPage.routeName,
          page: () => const RatingReviewPage(),
        ),
        GetPage(
          name: PromoPage.routeName,
          page: () => const PromoPage(),
        ),
        GetPage(
          name: NotificationsPage.routeName,
          page: () => const NotificationsPage(),
        ),
        GetPage(
          name: '/payment',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return PaymentPage(
              bookingId: args?['bookingId'] ?? '',
              amount: (args?['amount'] ?? 0.0).toDouble(),
              customerName: args?['customerName'] ?? '',
              customerEmail: args?['customerEmail'] ?? '',
              customerPhone: args?['customerPhone'],
            );
          },
        ),
        GetPage(
          name: PaymentHistoryPage.routeName,
          page: () => const PaymentHistoryPage(),
        ),
        GetPage(
          name: InvoicePage.routeName,
          page: () => const InvoicePage(),
        ),
      ],
    ));
  }
}
