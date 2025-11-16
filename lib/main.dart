import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/home_page.dart';
import 'pages/mediaquery_demo.dart';
import 'pages/layoutbuilder_demo.dart';
import 'pages/animatedcontainer_demo.dart';
import 'pages/animationcontroller_demo.dart';
import 'pages/weather_demo.dart';
import 'pages/performance_comparison_page.dart';
import 'pages/async_handling_page.dart';
import 'pages/error_handling_analysis_page.dart';
import 'pages/performance_report_page.dart';

void main() {
  runApp(const CleaningServiceApp());
}

class CleaningServiceApp extends StatefulWidget {
  const CleaningServiceApp({super.key});

  @override
  State<CleaningServiceApp> createState() => _CleaningServiceAppState();
}

class _CleaningServiceAppState extends State<CleaningServiceApp> {
  ThemeMode _mode = ThemeMode.system;

  void _setMode(bool dark) {
    setState(() {
      _mode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );

    return GetMaterialApp(
      title: 'Layanan Kebersihan',
      theme: ThemeData(
        colorScheme: light,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      themeMode: _mode,
      routes: {
        '/': (_) => HomePage(
              isDark: _mode == ThemeMode.dark,
              onChangeTheme: _setMode,
            ),
        MediaQueryDemoPage.routeName: (_) => const MediaQueryDemoPage(),
        LayoutBuilderDemoPage.routeName: (_) => const LayoutBuilderDemoPage(),
        AnimatedContainerDemoPage.routeName: (_) => const AnimatedContainerDemoPage(),
        AnimationControllerDemoPage.routeName: (_) => const AnimationControllerDemoPage(),
        WeatherDemoPage.routeName: (_) => const WeatherDemoPage(),
        PerformanceComparisonPage.routeName: (_) => const PerformanceComparisonPage(),
        AsyncHandlingPage.routeName: (_) => const AsyncHandlingPage(),
        ErrorHandlingAnalysisPage.routeName: (_) => const ErrorHandlingAnalysisPage(),
        PerformanceReportPage.routeName: (_) => const PerformanceReportPage(),
      },
      initialRoute: '/',
    );
  }
}
