import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';

/// Widget untuk demo storage operations
class StorageDemoCard extends StatelessWidget {
  const StorageDemoCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StorageController>();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Performance Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Online Status
            Obx(() => Row(
              children: [
                Icon(
                  controller.isOnline.value ? Icons.cloud_done : Icons.cloud_off,
                  color: controller.isOnline.value ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.isOnline.value ? 'Online' : 'Offline',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )),
            
            const SizedBox(height: 12),
            
            // Pending Bookings Count
            Obx(() => Text(
              'Pending Bookings: ${controller.pendingBookingsCount.value}',
            )),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showPerformanceReport(context, controller);
                    },
                    child: const Text('View Performance'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      controller.syncNow();
                    },
                    child: Obx(() => controller.syncInProgress.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sync Now')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      controller.clearAllLogs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs cleared')),
                      );
                    },
                    child: const Text('Clear Logs'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPerformanceReport(BuildContext context, StorageController controller) {
    final report = controller.getPerformanceReport();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportSection('SharedPreferences', report['prefs']),
                      const SizedBox(height: 12),
                      _buildReportSection('Hive', report['hive']),
                      const SizedBox(height: 12),
                      _buildReportSection('Supabase', report['supabase']),
                      const SizedBox(height: 12),
                      _buildReportSection('Sync', report['sync']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReportSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text('Total Operations: ${data['total'] ?? 0}'),
        Text('Avg Time: ${data['avgTime'] ?? 0}ms'),
        Text('Success Rate: ${data['successRate'] ?? "0%"}'),
      ],
    );
  }
}
