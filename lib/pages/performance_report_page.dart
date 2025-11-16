import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/performance_controller.dart';
import '../controllers/async_controller.dart';

class PerformanceReportPage extends StatelessWidget {
  static const routeName = '/performance-report';

  const PerformanceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final perfController = Get.put(PerformanceController());
    final asyncController = Get.put(AsyncController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report & Recommendations'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Summary
            Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Eksekutif',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Laporan ini merangkum hasil eksperimen performa HTTP library (http vs Dio), '
                      'analisis error handling & logging, dan perbandingan async handling methods. '
                      'Tujuan: membantu developer memilih library dan approach yang paling sesuai untuk proyek mereka.',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.8), height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // HTTP vs Dio Summary
            _buildSummarySection(
              context,
              'HTTP vs Dio Library Comparison',
              [
                {
                  'title': 'HTTP Library',
                  'color': Colors.blue,
                  'pros': [
                    'Lightweight dan minimal dependency',
                    'Mudah dipelajari untuk pemula',
                    'Cocok untuk aplikasi sederhana',
                    'Performa cepat untuk single request',
                  ],
                  'cons': [
                    'Error handling manual dan verbose',
                    'Tidak ada built-in logging',
                    'Sulit untuk aplikasi kompleks',
                    'Retry logic harus manual',
                  ],
                },
                {
                  'title': 'Dio Library',
                  'color': Colors.orange,
                  'pros': [
                    'Built-in interceptor untuk logging',
                    'Error handling terstruktur (DioException)',
                    'Cocok untuk aplikasi berskala besar',
                    'Fitur lengkap (retry, timeout, dll)',
                  ],
                  'cons': [
                    'Lebih berat (lebih banyak dependency)',
                    'Kurva pembelajaran lebih curam',
                    'Overhead untuk aplikasi sederhana',
                    'Konfigurasi lebih kompleks',
                  ],
                },
              ],
            ),
            const SizedBox(height: 24),
            // Async Handling Summary
            _buildAsyncSummarySection(context),
            const SizedBox(height: 24),
            // Recommendations
            _buildRecommendationsSection(context),
            const SizedBox(height: 24),
            // Implementation Guide
            _buildImplementationGuide(context),
            const SizedBox(height: 24),
            // Conclusion
            Card(
              color: cs.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: cs.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Kesimpulan',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilihan antara HTTP dan Dio bergantung pada kebutuhan proyek:\n\n'
                      '• Untuk MVP atau prototype: gunakan HTTP\n'
                      '• Untuk production dengan banyak API: gunakan Dio\n'
                      '• Untuk async handling: prioritaskan async-await untuk readability\n'
                      '• Selalu gunakan GetX untuk state management yang konsisten\n\n'
                      'Kombinasi terbaik untuk aplikasi cleaning service:\n'
                      'Dio + GetX + Async-Await = Scalable, Maintainable, Professional',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.8),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
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
                            color: item['color'],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['title'],
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kelebihan:',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...((item['pros'] as List<String>).map((pro) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✓ ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(pro, style: TextStyle(color: cs.onSurface.withOpacity(0.8))),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 12),
                    Text(
                      'Kekurangan:',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...((item['cons'] as List<String>).map((con) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✗ ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(con, style: TextStyle(color: cs.onSurface.withOpacity(0.8))),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAsyncSummarySection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Async Handling Methods Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
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
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Async-Await (Recommended)',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAsyncFeature('Readability', 'Kode linear dan mudah dipahami', cs),
                _buildAsyncFeature('Debugging', 'Stack trace yang jelas dan informatif', cs),
                _buildAsyncFeature('Error Handling', 'try-catch yang familiar dan intuitif', cs),
                _buildAsyncFeature('Maintainability', 'Mudah dimodifikasi dan di-extend', cs),
                _buildAsyncFeature('Performance', 'Sama dengan callback, tapi lebih clean', cs),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Callback Chaining (Legacy)',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAsyncFeature('Readability', 'Nested callbacks (callback hell)', cs, isNegative: true),
                _buildAsyncFeature('Debugging', 'Stack trace yang kompleks dan membingungkan', cs, isNegative: true),
                _buildAsyncFeature('Error Handling', 'Perlu .catchError() yang verbose', cs, isNegative: true),
                _buildAsyncFeature('Maintainability', 'Sulit dimodifikasi, rawan bug', cs, isNegative: true),
                _buildAsyncFeature('Performance', 'Sama dengan async-await', cs),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAsyncFeature(String label, String value, ColorScheme cs, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNegative ? '✗ ' : '✓ ',
            style: TextStyle(
              color: isNegative ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Implementasi',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Untuk Aplikasi Cleaning Service:\n\n'
              '1. HTTP Library:\n'
              '   - Gunakan untuk API calls sederhana\n'
              '   - Cocok untuk MVP atau prototype\n'
              '   - Minimal dependency\n\n'
              '2. Dio Library:\n'
              '   - Gunakan untuk production\n'
              '   - Implementasi logging interceptor\n'
              '   - Setup error handling yang robust\n\n'
              '3. Async Handling:\n'
              '   - Selalu gunakan async-await\n'
              '   - Hindari callback chaining\n'
              '   - Gunakan try-catch untuk error handling\n\n'
              '4. State Management:\n'
              '   - Gunakan GetX untuk semua controller\n'
              '   - Pisahkan logic dari UI\n'
              '   - Implementasikan reactive programming',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.8),
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImplementationGuide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Implementasi Best Practice',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildGuideStep(
              '1',
              'Setup Dio dengan Interceptor',
              'Konfigurasi Dio dengan LoggingInterceptor untuk transparansi request/response',
              cs,
            ),
            _buildGuideStep(
              '2',
              'Implementasi Service Layer',
              'Buat service class untuk setiap API endpoint dengan error handling yang konsisten',
              cs,
            ),
            _buildGuideStep(
              '3',
              'Gunakan GetX Controller',
              'Implementasikan controller untuk state management dan business logic',
              cs,
            ),
            _buildGuideStep(
              '4',
              'Async-Await Pattern',
              'Gunakan async-await untuk operasi asynchronous yang mudah dibaca',
              cs,
            ),
            _buildGuideStep(
              '5',
              'Error Handling',
              'Implementasikan try-catch dan tampilkan error message yang user-friendly',
              cs,
            ),
            _buildGuideStep(
              '6',
              'Testing',
              'Test semua scenario: success, error, timeout, network failure',
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
