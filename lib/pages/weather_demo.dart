import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/weather_controller.dart';
import '../models/weather.dart';

class WeatherDemoPage extends StatelessWidget {
  static const routeName = '/weather-demo';

  const WeatherDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WeatherController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca & Rekomendasi Cleaning'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    const Text('Memuat data cuaca...'),
                  ],
                ),
              )
            : controller.errorMessage.value.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: cs.error),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => controller.fetchWeather(controller.selectedCity.value),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          color: cs.surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<String>(
                              value: controller.selectedCity.value,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: controller.cities
                                  .map((city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city),
                                      ))
                                  .toList(),
                              onChanged: (city) {
                                if (city != null) {
                                  controller.fetchWeather(city);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (controller.weatherData.value != null) ...[
                          Card(
                            elevation: 2,
                            color: cs.primary.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    controller.weatherData.value!.getWeatherIcon(),
                                    size: 64,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${controller.weatherData.value!.temperature.toStringAsFixed(1)}°C',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.weatherData.value!.getWeatherDescription(),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Icon(Icons.opacity, color: cs.primary),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${controller.weatherData.value!.humidity.toStringAsFixed(0)}%',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const Text('Kelembaban'),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Icon(Icons.air, color: cs.primary),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${controller.weatherData.value!.windSpeed.toStringAsFixed(1)} km/h',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const Text('Kecepatan Angin'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Card(
                            elevation: 2,
                            color: cs.tertiary.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.cleaning_services, color: cs.tertiary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rekomendasi Cleaning',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: cs.tertiary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    controller.weatherData.value!.getCleaningRecommendation(),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          height: 1.6,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Layanan yang Direkomendasikan:',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecommendedServices(context, controller.weatherData.value!, cs),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRecommendedServices(
    BuildContext context,
    WeatherData weather,
    ColorScheme cs,
  ) {
    final services = _getRecommendedServices(weather.weatherCode);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(service['icon'], size: 32, color: service['color']),
                const SizedBox(height: 8),
                Text(
                  service['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getRecommendedServices(String weatherCode) {
    if (weatherCode == '0' || weatherCode == '1') {
      // Cerah - outdoor services
      return [
        {'name': 'Cuci Karpet', 'icon': Icons.layers, 'color': Colors.orange},
        {'name': 'Cuci Sofa', 'icon': Icons.event_seat, 'color': Colors.indigo},
        {'name': 'Cat Dinding', 'icon': Icons.format_paint, 'color': Colors.purple},
        {'name': 'Pel Lantai', 'icon': Icons.cleaning_services, 'color': Colors.teal},
      ];
    } else if (weatherCode == '2' || weatherCode == '3') {
      // Berawan - indoor services
      return [
        {'name': 'Pel Lantai', 'icon': Icons.cleaning_services, 'color': Colors.teal},
        {'name': 'Cat Dinding', 'icon': Icons.format_paint, 'color': Colors.purple},
        {'name': 'Laundry', 'icon': Icons.local_laundry_service, 'color': Colors.green},
        {'name': 'Cuci Sofa', 'icon': Icons.event_seat, 'color': Colors.indigo},
      ];
    } else {
      // Hujan/Salju - indoor only
      return [
        {'name': 'Laundry', 'icon': Icons.local_laundry_service, 'color': Colors.green},
        {'name': 'Pel Lantai', 'icon': Icons.cleaning_services, 'color': Colors.teal},
        {'name': 'Angkut Sampah', 'icon': Icons.delete_sweep, 'color': Colors.red},
        {'name': 'Cuci Sofa', 'icon': Icons.event_seat, 'color': Colors.indigo},
      ];
    }
  }
}
