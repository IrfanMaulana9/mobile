import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/performance_controller.dart';
import '../models/performance_result.dart';

class PerformanceComparisonPage extends StatelessWidget {
  static const routeName = '/performance-comparison';

  const PerformanceComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PerformanceController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP vs Dio Performance'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // City Selection
                    Text(
                      'Pilih Kota:',
                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        children: controller.cityCoordinates.keys.map((city) {
                          final isSelected = controller.selectedCity.value == city;
                          return FilterChip(
                            label: Text(city),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) controller.selectedCity.value = city;
                            },
                            backgroundColor: cs.surface,
                            selectedColor: cs.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? cs.onPrimary : cs.onSurface,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Iterations Selection
                    Text(
                      'Jumlah Iterasi:',
                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Slider(
                        value: controller.iterations.value.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${controller.iterations.value}x',
                        onChanged: (value) {
                          controller.iterations.value = value.toInt();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Run Test Button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value ? null : () => controller.runPerformanceTest(),
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(controller.isLoading.value ? 'Testing...' : 'Jalankan Test'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Results Section
            Obx(
              () {
                if (controller.httpResults.isEmpty && controller.dioResults.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Tekan tombol "Jalankan Test" untuk memulai pengujian performa',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Winner Announcement
                    if (controller.httpResults.isNotEmpty && controller.dioResults.isNotEmpty)
                      Card(
                        color: cs.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events, color: cs.primary, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pemenang',
                                      style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      controller.getWinner(),
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // HTTP Results
                    if (controller.httpResults.isNotEmpty) ...[
                      _buildLibraryStats(
                        context,
                        'HTTP Library',
                        controller.getHttpStats(),
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Dio Results
                    if (controller.dioResults.isNotEmpty) ...[
                      _buildLibraryStats(
                        context,
                        'Dio Library',
                        controller.getDioStats(),
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Detailed Results Table
                    if (controller.httpResults.isNotEmpty || controller.dioResults.isNotEmpty) ...[
                      Text(
                        'Detail Hasil Test',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildResultsTable(context, controller),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryStats(BuildContext context, String libraryName, PerformanceStats stats, Color color) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  libraryName,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Rata-rata Response Time',
              '${stats.averageResponseTime.toStringAsFixed(2)} ms',
              cs,
            ),
            _buildStatRow(
              'Tercepat',
              '${stats.fastestResponseTime} ms',
              cs,
            ),
            _buildStatRow(
              'Terlambat',
              '${stats.slowestResponseTime} ms',
              cs,
            ),
            _buildStatRow(
              'Success Rate',
              '${stats.successRate.toStringAsFixed(1)}%',
              cs,
            ),
            _buildStatRow(
              'Berhasil / Total',
              '${stats.successCount} / ${stats.results.length}',
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(BuildContext context, PerformanceController controller) {
    final cs = Theme.of(context).colorScheme;
    final allResults = [...controller.httpResults, ...controller.dioResults];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Library', style: TextStyle(color: cs.onSurface))),
          DataColumn(label: Text('Time (ms)', style: TextStyle(color: cs.onSurface))),
          DataColumn(label: Text('Status', style: TextStyle(color: cs.onSurface))),
        ],
        rows: allResults.map((result) {
          return DataRow(
            cells: [
              DataCell(Text(result.libraryName, style: TextStyle(color: cs.onSurface))),
              DataCell(Text('${result.responseTime}', style: TextStyle(color: cs.onSurface))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.statusCode == 200 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.statusCode == 200 ? 'OK' : 'Error',
                    style: TextStyle(
                      color: result.statusCode == 200 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
