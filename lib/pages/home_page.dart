import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/storage_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/weather_controller.dart';
import '../controllers/notification_controller.dart'; // Added notification controller import
import '../services/notification_service.dart';
import '../data/services.dart';
import '../data/promotions.dart';
import 'booking_page.dart';
import 'booking_history_page.dart'; // Added import for BookingHistoryPage
import 'rating_review_page.dart';
import 'account_page.dart'; // Added import for AccountPage
import 'promo_page.dart'; // Added import for PromoPage

class HomePage extends StatefulWidget {
  final bool isDark;
  final void Function(bool dark)? onChangeTheme;

  const HomePage({super.key, this.isDark = false, this.onChangeTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _isDark;
  int _selectedTab = 0;
  int? _activeServiceIndex;
  final storageController = Get.find<StorageController>();
  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();
  late final WeatherController weatherController;
  late final NotificationController
      notificationController; // Added notification controller

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    weatherController = Get.put(WeatherController());
    weatherController.fetchWeather('Malang');
    notificationController =
        Get.put(NotificationController()); // Initialize notification controller

    // Check new promo once on app start (best-effort)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNotifyNewPromo();
    });
  }

  Future<void> _checkAndNotifyNewPromo() async {
    try {
      // Give NotificationService a moment to finish initialization (best-effort).
      await Future.delayed(const Duration(milliseconds: 900));

      // pick newest promo by startDate (fallback to last item)
      final sorted = [...promotions]
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      final newest = sorted.isNotEmpty ? sorted.first : null;
      if (newest == null) return;

      // only notify for active promo (so user can immediately use it)
      if (!newest.isActive) return;

      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedId = prefs.getString('last_notified_promo_id') ?? '';

      if (lastNotifiedId == newest.id) return;

      await NotificationService().showNotification(
        title: '🔥 Promo Baru!',
        body:
            '${newest.title} - Diskon ${newest.discountPercentage}%. Tap untuk lihat promo.',
        payload: jsonEncode({
          'type': 'promo',
          'route': PromoPage.routeName,
          'promoId': newest.id,
        }),
        useCustomSound: true,
      );

      await prefs.setString('last_notified_promo_id', newest.id);
    } catch (e) {
      print('[HomePage] Promo notify error (ignored): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomePage(context, cs),
          const BookingHistoryPage(),
          const PromoPage(),
          const RatingReviewPage(),
          const AccountPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Rating',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, ColorScheme cs) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          expandedHeight: 240,
          backgroundColor: cs.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pembersihan Profesional',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'yang Berkualitas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilih pembersihan profesional yang berkualitas\nuntuk kebersihan yang teramankan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        // Notification bell with badge and theme toggle
                        Row(
                          children: [
                            // Notification bell with badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  tooltip: 'Notifikasi',
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Get.toNamed('/notifications');
                                  },
                                ),
                                Obx(() {
                                  final unreadCount =
                                      notificationController.unreadCount;
                                  if (unreadCount == 0)
                                    return const SizedBox.shrink();

                                  return Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            // Theme toggle
                            IconButton(
                              tooltip: _isDark ? 'Mode Terang' : 'Mode Gelap',
                              icon: Icon(
                                _isDark ? Icons.light_mode : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() => _isDark = !_isDark);
                                widget.onChangeTheme?.call(_isDark);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari layanan terdekat',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, color: cs.primary),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paket Layanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              // Give enough height so the "expanded" card + button never overflows.
              mainAxisExtent: 270,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= layanan.length) return SizedBox.shrink();
                final service = layanan[index];
                final isActive = _activeServiceIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeServiceIndex = isActive ? null : index;
                    });
                  },
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    scale: isActive ? 1.06 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isActive ? 14 : 12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(isActive ? 18 : 12),
                        border: Border.all(
                          color: isActive
                              ? service.warna.withValues(alpha: 0.55)
                              : cs.outlineVariant,
                          width: isActive ? 1.6 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            height: isActive ? 92 : 80,
                            decoration: BoxDecoration(
                              color: service.warna
                                  .withValues(alpha: isActive ? 0.20 : 0.15),
                              borderRadius:
                                  BorderRadius.circular(isActive ? 16 : 12),
                            ),
                            child: Icon(
                              service.ikon,
                              color: service.warna,
                              size: isActive ? 46 : 40,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            service.nama,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.deskripsi,
                            textAlign: TextAlign.center,
                            maxLines: isActive ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  String serviceType = '';
                                  final name = service.nama.toLowerCase();
                                  if (name.contains('indoor'))
                                    serviceType = 'indoor';
                                  if (name.contains('outdoor'))
                                    serviceType = 'outdoor';
                                  if (name.contains('deep'))
                                    serviceType = 'deep';
                                  if (name.contains('window'))
                                    serviceType = 'window';

                                  Get.toNamed(
                                    BookingPage.routeName,
                                    arguments: {
                                      'serviceName': service.nama,
                                      'serviceType': serviceType,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.shopping_cart, size: 16),
                                label: const Text('Pesan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: service.warna,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: layanan.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final weather = weatherController.weatherData.value;
              final isLoading = weatherController.isLoading.value;

              if (isLoading) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        cs.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              if (weather == null) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        cs.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak dapat memuat data cuaca',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onPrimary,
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuaca di Malang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              weather.getWeatherDescription(),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${weather.temperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.onPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                weather.getWeatherIcon(),
                                color: cs.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kelembaban',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                              Text(
                                '${weather.humidity.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keuntungan Berlangganan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                        cs, '✓', 'Ahlimu yang berpengalaman', Colors.green),
                    _buildBenefitItem(
                        cs, '✓', 'Garansi uang kembali 100%', Colors.green),
                    _buildBenefitItem(cs, '✓', 'Baik pagi hari berbeda tarian',
                        Colors.orange),
                    _buildBenefitItem(cs, '✓',
                        'Mudah dijadwalkan dan interaktif', Colors.green),
                    _buildBenefitItem(
                        cs,
                        '✓',
                        'Berhasil hasil yang sempurna kami jamin',
                        Colors.green),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildBenefitItem(
      ColorScheme cs, String icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
