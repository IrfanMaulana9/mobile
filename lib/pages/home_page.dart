import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/weather_controller.dart';
import '../data/services.dart';
import 'booking_page.dart';
import 'booking_history_page.dart'; // Added import for BookingHistoryPage
import 'weather_demo.dart';
import 'performance_stats_page.dart';
import 'auth_page.dart';
import 'notes_page.dart';
import 'account_page.dart'; // Added import for AccountPage
import 'promo_page.dart'; // Added import for PromoPage
import 'gps_menu_page.dart'; // Added GPS menu page import

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
  final storageController = Get.find<StorageController>();
  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();
  late final WeatherController weatherController;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    weatherController = Get.put(WeatherController());
    weatherController.fetchWeather('Malang');
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
          const NotesPage(),
          const GPSMenuPage(), // Updated to use GPS menu page instead of direct location tracker
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
            icon: Icon(Icons.note_alt_outlined),
            label: 'Catatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'GPS',
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= layanan.length) return SizedBox.shrink();
                final service = layanan[index];
                
                return GestureDetector(
                  onTap: () {
                    Get.toNamed(BookingPage.routeName);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: service.warna.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service.ikon,
                          color: service.warna,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        service.nama,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.deskripsi,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    _buildBenefitItem(cs, '✓', 'Ahlimu yang berpengalaman', Colors.green),
                    _buildBenefitItem(cs, '✓', 'Garansi uang kembali 100%', Colors.green),
                    _buildBenefitItem(cs, '✓', 'Baik pagi hari berbeda tarian', Colors.orange),
                    _buildBenefitItem(cs, '✓', 'Mudah dijadwalkan dan interaktif', Colors.green),
                    _buildBenefitItem(cs, '✓', 'Berhasil hasil yang sempurna kami jamin', Colors.green),
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

  Widget _buildBenefitItem(ColorScheme cs, String icon, String text, Color color) {
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
