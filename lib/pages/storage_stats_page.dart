import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';
import '../models/hive_models.dart';
import 'notes_page.dart'; // Added notes page import
import 'booking_details_page.dart'; // Added booking details page import

/// Page untuk menampilkan storage statistics dan booking history
class StorageStatsPage extends StatelessWidget {
  static const String routeName = '/storage-stats';
  
  const StorageStatsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StorageController>();
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Statistics'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.checkOnlineStatus();
              Get.forceAppUpdate();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.checkOnlineStatus();
          await controller.syncNow();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(controller, cs),
              
              const SizedBox(height: 24),
              
              // Statistics Cards
              Text(
                'Storage Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildStorageCards(controller, cs),
              
              const SizedBox(height: 24),
              
              // Booking History
              Text(
                'Booking History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildBookingList(controller, cs),
              
              const SizedBox(height: 24),
              
              // Actions
              _buildActionButtons(controller, context, cs),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard(StorageController controller, ColorScheme cs) {
    return Obx(() => Card(
      color: controller.isOnline.value ? cs.primaryContainer : cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  controller.isOnline.value ? Icons.cloud_done : Icons.cloud_off,
                  color: controller.isOnline.value ? cs.primary : cs.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isOnline.value ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: controller.isOnline.value 
                              ? cs.onPrimaryContainer 
                              : cs.onErrorContainer,
                        ),
                      ),
                      Text(
                        controller.isOnline.value
                            ? 'Connected to cloud storage'
                            : 'Working in offline mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.isOnline.value 
                              ? cs.onPrimaryContainer 
                              : cs.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.pendingBookingsCount.value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${controller.pendingBookingsCount.value} pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (controller.pendingBookingsCount.value > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.syncInProgress.value 
                      ? null 
                      : () => controller.syncNow(),
                  icon: controller.syncInProgress.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    controller.syncInProgress.value ? 'Syncing...' : 'Sync Now',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }
  
  Widget _buildStorageCards(StorageController controller, ColorScheme cs) {
    return Obx(() {
      final totalBookings = controller.getAllBookings().length;
      final pendingBookings = controller.getPendingBookings().length;
      final syncedBookings = totalBookings - pendingBookings;
      
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  cs,
                  icon: Icons.storage,
                  title: 'Total Bookings',
                  value: totalBookings.toString(),
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  cs,
                  icon: Icons.cloud_done,
                  title: 'Synced',
                  value: syncedBookings.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  cs,
                  icon: Icons.cloud_upload,
                  title: 'Pending Sync',
                  value: pendingBookings.toString(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  cs,
                  icon: Icons.phone_android,
                  title: 'Local Storage',
                  value: 'Hive',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
  
  Widget _buildStatCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingList(StorageController controller, ColorScheme cs) {
    return Obx(() {
      final bookings = controller.getAllBookings();
      
      if (bookings.isEmpty) {
        return Card(
          color: cs.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return Column(
        children: bookings.map((booking) {
          return Card(
            color: cs.surface,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: booking.synced ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                child: Icon(
                  booking.synced ? Icons.check : Icons.upload,
                ),
              ),
              title: Text(
                booking.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.serviceName),
                  Text(
                    booking.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${booking.totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => _showBookingDetail(booking, cs),
            ),
          );
        }).toList(),
      );
    });
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showBookingDetail(HiveBooking booking, ColorScheme cs) {
    Get.dialog(
      AlertDialog(
        title: Text(booking.customerName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Service', booking.serviceName),
              _buildDetailRow('Phone', booking.phoneNumber),
              _buildDetailRow('Address', booking.address),
              _buildDetailRow(
                'Date', 
                '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}'
              ),
              _buildDetailRow('Time', booking.bookingTime),
              _buildDetailRow('Price', 'Rp ${booking.totalPrice.toStringAsFixed(0)}'),
              _buildDetailRow('Status', booking.status.toUpperCase()),
              _buildDetailRow('Synced', booking.synced ? 'Yes' : 'No'),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notes', booking.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.to(
                () => const NotesPage(),
              );
            },
            icon: const Icon(Icons.note),
            label: const Text('Notes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(
    StorageController controller,
    BuildContext context,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed('/performance-stats'),
            icon: const Icon(Icons.speed),
            label: const Text('View Performance Report'),
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
            onPressed: () => _showClearDataDialog(controller, context),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showClearDataDialog(StorageController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all bookings from local storage. '
          'Synced bookings in cloud will remain. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
