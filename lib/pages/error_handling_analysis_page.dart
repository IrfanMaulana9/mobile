import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/performance_controller.dart';

class ErrorHandlingAnalysisPage extends StatelessWidget {
  static const routeName = '/error-handling-analysis';

  const ErrorHandlingAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PerformanceController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling & Logging Analysis'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Card
            Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analisis Error Handling & Logging',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Membandingkan mekanisme penanganan error dan logging antara HTTP dan Dio library untuk memahami kelebihan dan kekurangan masing-masing.',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // HTTP Library Analysis
            _buildLibraryAnalysis(
              context,
              'HTTP Library',
              'Manual Error Handling',
              [
                'Menggunakan try-catch untuk menangkap exception',
                'Perlu manual check status code (response.statusCode)',
                'Logging harus diimplementasikan manual dengan print()',
                'Error handling lebih verbose dan repetitif',
                'Cocok untuk aplikasi sederhana dengan error handling minimal',
              ],
              [
                'try {',
                '  final response = await http.get(uri);',
                '  if (response.statusCode != 200) {',
                '    print("Error: \${response.statusCode}");',
                '  }',
                '} catch (e) {',
                '  print("Exception: \$e");',
                '}',
              ],
              Colors.blue,
            ),
            const SizedBox(height: 24),
            // Dio Library Analysis
            _buildLibraryAnalysis(
              context,
              'Dio Library',
              'Built-in Error Handling & Logging',
              [
                'Interceptor otomatis untuk request/response logging',
                'DioException dengan tipe error yang spesifik',
                'Logging terintegrasi tanpa perlu manual print()',
                'Error handling lebih terstruktur dan konsisten',
                'Cocok untuk aplikasi berskala besar dengan transparansi tinggi',
              ],
              [
                'dio.interceptors.add(LoggingInterceptor());',
                '',
                'try {',
                '  final response = await dio.get(endpoint);',
                '} on DioException catch (e) {',
                '  print("DioException: \${e.message}");',
                '  print("Type: \${e.type}");',
                '}',
              ],
              Colors.orange,
            ),
            const SizedBox(height: 24),
            // Comparison Table
            _buildComparisonTable(context),
            const SizedBox(height: 24),
            // Recommendations
            _buildRecommendations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryAnalysis(
    BuildContext context,
    String libraryName,
    String subtitle,
    List<String> features,
    List<String> codeExample,
    Color color,
  ) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libraryName,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Fitur Utama:',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Text(
              'Contoh Kode:',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                codeExample.join('\n'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tabel Perbandingan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Aspek', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('HTTP', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Dio', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                ],
                rows: [
                  _buildComparisonRow('Error Handling', 'Manual try-catch', 'DioException + Interceptor', cs),
                  _buildComparisonRow('Logging', 'Manual print()', 'Built-in Interceptor', cs),
                  _buildComparisonRow('Status Code Check', 'Manual', 'Otomatis', cs),
                  _buildComparisonRow('Timeout Handling', 'Manual', 'Built-in', cs),
                  _buildComparisonRow('Retry Logic', 'Manual', 'Interceptor', cs),
                  _buildComparisonRow('Request/Response Inspection', 'Manual', 'Otomatis', cs),
                  _buildComparisonRow('Kurva Pembelajaran', 'Mudah', 'Sedang', cs),
                  _buildComparisonRow('Cocok untuk Skala', 'Kecil-Sedang', 'Sedang-Besar', cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildComparisonRow(String aspect, String http, String dio, ColorScheme cs) {
    return DataRow(
      cells: [
        DataCell(Text(aspect, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600))),
        DataCell(Text(http, style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 12))),
        DataCell(Text(dio, style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 12))),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
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
                Icon(Icons.lightbulb, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Penggunaan',
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
              'Gunakan HTTP jika:\n'
              '• Aplikasi sederhana dengan API calls minimal\n'
              '• Tidak memerlukan logging detail\n'
              '• Ingin dependency minimal\n\n'
              'Gunakan Dio jika:\n'
              '• Aplikasi berskala besar dengan banyak API calls\n'
              '• Memerlukan logging dan debugging yang detail\n'
              '• Perlu error handling yang robust\n'
              '• Memerlukan interceptor untuk request/response manipulation\n'
              '• Ingin retry logic dan timeout handling yang fleksibel',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.8),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
