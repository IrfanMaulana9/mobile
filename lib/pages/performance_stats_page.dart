import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';
import 'dart:convert';

/// Page untuk detailed performance metrics dengan visualisasi
class PerformanceStatsPage extends StatelessWidget {
  static const String routeName = '/performance-stats';
  
  const PerformanceStatsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StorageController>();
    final cs = Theme.of(context).colorScheme;
    final report = controller.getPerformanceReport();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Get.back();
              Get.toNamed('/performance-stats');
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyReport(report),
            tooltip: 'Copy JSON',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(report, cs),
            
            const SizedBox(height: 24),
            
            Text(
              'Storage Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // SharedPreferences Stats
            _buildStorageMetricCard('SharedPreferences', report['prefs'], cs, Colors.blue),
            
            const SizedBox(height: 12),
            
            // Hive Stats
            _buildStorageMetricCard('Hive', report['hive'], cs, Colors.purple),
            
            const SizedBox(height: 12),
            
            // Supabase Stats
            _buildStorageMetricCard('Supabase', report['supabase'], cs, Colors.green),
            
            const SizedBox(height: 12),
            
            // Sync Manager Stats
            _buildStorageMetricCard('Sync Manager', report['sync'], cs, Colors.orange),
            
            const SizedBox(height: 24),
            
            // Raw JSON Section
            Text(
              'Raw JSON Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildRawJSONCard(report, cs),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionButtons(controller, cs),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(Map<String, dynamic> report, ColorScheme cs) {
    final timestamp = report['timestamp'] ?? 'N/A';
    final pendingCount = report['pendingBookingsCount'] ?? 0;
    final totalBookings = report['totalBookings'] ?? 0;
    final isOnline = report['isOnline'] ?? false;
    
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: cs.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Performance Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSummaryRow('Timestamp', timestamp, cs),
            _buildSummaryRow('Online Status', isOnline ? 'Online' : 'Offline', cs),
            _buildSummaryRow('Total Bookings', totalBookings.toString(), cs),
            _buildSummaryRow('Pending Sync', pendingCount.toString(), cs),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStorageMetricCard(
    String title,
    Map<String, dynamic> data,
    ColorScheme cs,
    Color accentColor,
  ) {
    final total = data['total'] ?? 0;
    final avgTime = data['avgTime'] ?? 0;
    final successRate = data['successRate'] ?? '0%';
    
    return Card(
      color: cs.surface,
      child: ExpansionTile(
        leading: Icon(
          _getStorageIcon(title),
          color: accentColor,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$total operations • Avg: ${avgTime}ms',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMetricRow(
                  'Total Operations',
                  total.toString(),
                  Icons.functions,
                  cs,
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'Average Time',
                  '${avgTime}ms',
                  Icons.timer,
                  cs,
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'Success Rate',
                  successRate.toString(),
                  Icons.check_circle,
                  cs,
                ),
                
                // Performance indicator
                const SizedBox(height: 12),
                _buildPerformanceBar(avgTime, cs, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getStorageIcon(String title) {
    if (title.contains('Preferences')) return Icons.settings;
    if (title.contains('Hive')) return Icons.storage;
    if (title.contains('Supabase')) return Icons.cloud;
    if (title.contains('Sync')) return Icons.sync;
    return Icons.storage;
  }
  
  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPerformanceBar(int avgTime, ColorScheme cs, Color accentColor) {
    // Performance rating: <10ms = Excellent, 10-50ms = Good, 50-100ms = Fair, >100ms = Poor
    String rating;
    double progress;
    Color ratingColor;
    
    if (avgTime < 10) {
      rating = 'Excellent';
      progress = 1.0;
      ratingColor = Colors.green;
    } else if (avgTime < 50) {
      rating = 'Good';
      progress = 0.75;
      ratingColor = Colors.lightGreen;
    } else if (avgTime < 100) {
      rating = 'Fair';
      progress = 0.5;
      ratingColor = Colors.orange;
    } else {
      rating = 'Poor';
      progress = 0.25;
      ratingColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance:',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ratingColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rating,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: cs.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(ratingColor),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRawJSONCard(Map<String, dynamic> report, ColorScheme cs) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(report);
    
    return Card(
      color: cs.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'JSON Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyReport(report),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(StorageController controller, ColorScheme cs) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportReport(controller.getPerformanceReport()),
            icon: const Icon(Icons.download),
            label: const Text('Export Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: cs.onSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.clearAllLogs();
              Get.snackbar(
                'Success',
                'Performance logs cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear Logs'),
          ),
        ),
      ],
    );
  }
  
  void _copyReport(Map<String, dynamic> report) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(report);
    Clipboard.setData(ClipboardData(text: jsonString));
    Get.snackbar(
      'Success',
      'Report copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      duration: const Duration(seconds: 2),
    );
  }
  
  void _exportReport(Map<String, dynamic> report) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(report);
    print('=== PERFORMANCE REPORT ===');
    print(jsonString);
    print('=========================');
    
    Get.snackbar(
      'Exported',
      'Report printed to console',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}