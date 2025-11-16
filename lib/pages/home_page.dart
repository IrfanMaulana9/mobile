import 'package:flutter/material.dart';
import 'mediaquery_demo.dart';
import 'layoutbuilder_demo.dart';
import 'animatedcontainer_demo.dart';
import 'animationcontroller_demo.dart';
import 'weather_demo.dart';
import 'performance_comparison_page.dart';
import 'async_handling_page.dart';
import 'error_handling_analysis_page.dart';
import 'performance_report_page.dart';

class HomePage extends StatefulWidget {
  final bool isDark;
  final void Function(bool dark)? onChangeTheme;

  const HomePage({super.key, this.isDark = false, this.onChangeTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  Route _fadeSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondary, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  Widget _navTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget page,
    required String heroTag,
    IconData icon = Icons.cleaning_services,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surface,
      child: ListTile(
        leading: Hero(
          tag: heroTag,
          child: CircleAvatar(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            child: Icon(icon),
          ),
        ),
        title: Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
        trailing: Icon(Icons.chevron_right, color: cs.onSurface),
        onTap: () => Navigator.of(context).push(_fadeSlideRoute(page)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Kebersihan - Demo'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            tooltip: _isDark ? 'Ubah ke Mode Terang' : 'Ubah ke Mode Gelap',
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() => _isDark = !_isDark);
              widget.onChangeTheme?.call(_isDark);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'API & Weather Integration',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _navTile(
            context,
            title: 'Cuaca & Rekomendasi Cleaning',
            subtitle: 'API Open-Meteo: Cuaca real-time + saran layanan',
            page: const WeatherDemoPage(),
            heroTag: WeatherDemoPage.routeName,
            icon: Icons.cloud_queue,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'HTTP Performance Experiments',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _navTile(
            context,
            title: 'HTTP vs Dio Performance',
            subtitle: 'Bandingkan performa 2 library HTTP dengan multiple tests',
            page: const PerformanceComparisonPage(),
            heroTag: PerformanceComparisonPage.routeName,
            icon: Icons.speed,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'Async Handling Experiments',
            subtitle: 'Bandingkan async-await vs callback chaining',
            page: const AsyncHandlingPage(),
            heroTag: AsyncHandlingPage.routeName,
            icon: Icons.timeline,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'Error Handling & Logging',
            subtitle: 'Analisis error handling HTTP vs Dio dengan logging',
            page: const ErrorHandlingAnalysisPage(),
            heroTag: ErrorHandlingAnalysisPage.routeName,
            icon: Icons.bug_report,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'Performance Report',
            subtitle: 'Laporan lengkap & rekomendasi implementasi',
            page: const PerformanceReportPage(),
            heroTag: PerformanceReportPage.routeName,
            icon: Icons.assessment,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'UI/UX Demos',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _navTile(
            context,
            title: 'Demo MediaQuery',
            subtitle: 'UI responsif (breakpoint global) untuk grid layanan',
            page: const MediaQueryDemoPage(),
            heroTag: MediaQueryDemoPage.routeName,
            icon: Icons.grid_view,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'Demo LayoutBuilder',
            subtitle: 'Komponen adaptif (ruang lokal) untuk grid reusable',
            page: const LayoutBuilderDemoPage(),
            heroTag: LayoutBuilderDemoPage.routeName,
            icon: Icons.dashboard_customize,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'AnimatedContainer (Implisit)',
            subtitle: 'Kotak layanan berubah saat ditekan',
            page: const AnimatedContainerDemoPage(),
            heroTag: AnimatedContainerDemoPage.routeName,
            icon: Icons.animation,
          ),
          const SizedBox(height: 12),
          _navTile(
            context,
            title: 'AnimationController (Eksplisit)',
            subtitle: 'Kontrol mulai/henti/ulang + durasi/curve',
            page: const AnimationControllerDemoPage(),
            heroTag: AnimationControllerDemoPage.routeName,
            icon: Icons.tune,
          ),
          const SizedBox(height: 24),
          Text(
            'Catatan:\n• Fokus: HTTP performance, async handling, error handling, responsivitas & animasi.\n• Gunakan dua emulator untuk membandingkan tampilan.\n• Lihat Performance Report untuk rekomendasi implementasi.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
