import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/async_controller.dart';
import '../models/async_result.dart';

class AsyncHandlingPage extends StatelessWidget {
  static const routeName = '/async-handling';

  const AsyncHandlingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AsyncController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Handling Experiments'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description Card
            Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eksperimen Async Handling',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Membandingkan dua pendekatan untuk menangani operasi asynchronous bertingkat:\n\n'
                      '1. Async-Await: Struktur linear, mudah dibaca\n'
                      '2. Callback Chaining: Nested callbacks, rawan callback hell',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Control Panel
            Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jalankan Test',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading.value ? null : () => controller.runAsyncAwaitTest(),
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
                              label: const Text('Test Async-Await'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading.value ? null : () => controller.runCallbackTest(),
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
                              label: const Text('Test Callback Chaining'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading.value ? null : () => controller.runBothTests(),
                              icon: controller.isLoading.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow_outlined),
                              label: const Text('Jalankan Kedua Test'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Results
            Obx(
              () {
                if (controller.asyncAwaitResult.value == null && controller.callbackResult.value == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Tekan tombol untuk menjalankan test',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comparison Card
                    if (controller.asyncAwaitResult.value != null && controller.callbackResult.value != null)
                      Card(
                        color: cs.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows, color: cs.primary, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perbandingan',
                                      style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      controller.getComparison(),
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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
                    // Async-Await Result
                    if (controller.asyncAwaitResult.value != null)
                      _buildResultCard(
                        context,
                        'Async-Await',
                        controller.asyncAwaitResult.value!,
                        Colors.blue,
                      ),
                    const SizedBox(height: 16),
                    // Callback Result
                    if (controller.callbackResult.value != null)
                      _buildResultCard(
                        context,
                        'Callback Chaining',
                        controller.callbackResult.value!,
                        Colors.orange,
                      ),
                    const SizedBox(height: 24),
                    // Analysis
                    Card(
                      color: cs.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analisis Readability & Maintainability',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.getReadabilityAnalysis(),
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.8),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, String methodName, AsyncResult result, Color color) {
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
                  methodName,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow('Total Time', '${result.totalTime} ms', cs),
            _buildResultRow('Weather Data', result.weatherData, cs),
            _buildResultRow('Recommendation', result.recommendation, cs, isMultiline: true),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildResultRow('Error', result.errorMessage!, cs, isError: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, ColorScheme cs, {bool isMultiline = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isError ? Colors.red : cs.onSurface,
              fontSize: isMultiline ? 12 : 14,
            ),
            maxLines: isMultiline ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
