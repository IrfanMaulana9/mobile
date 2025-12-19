import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../controllers/storage_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/rating_review_controller.dart';
import '../models/hive_models.dart';

class BookingHistoryPage extends StatefulWidget {
  static const String routeName = '/booking-history';
  
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late StorageController storageController;
  late BookingController bookingController;
  bool _isLocaleInitialized = false;
  
  @override
  void initState() {
    super.initState();
    storageController = Get.find<StorageController>();
    bookingController = Get.find<BookingController>();
    
    _initializeDateFormatting();
    _refreshBookings();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _isLocaleInitialized = true;
      });
    } catch (e) {
      print('[BookingHistoryPage] Error initializing date formatting: $e');
    }
  }

  Future<void> _refreshBookings() async {
    setState(() {});
    bookingController.refreshOfflineQueue();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Booking'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        elevation: 0,
        actions: [
          // Use GetBuilder instead of Obx to properly observe isOnline
          GetBuilder<StorageController>(
            builder: (controller) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Chip(
                  label: Text(
                    controller.isOnline.value ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: controller.isOnline.value ? Colors.green : Colors.orange,
                  avatar: Icon(
                    controller.isOnline.value ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GetBuilder<StorageController>(
        builder: (controller) {
          final bookings = storageController.getAllBookings();
          
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat booking',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/booking'),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Booking Baru'),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending (newest first)
          final sortedBookings = [...bookings]..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

          return RefreshIndicator(
            onRefresh: () async {
              if (storageController.isOnline.value) {
                // Push pending (offline-first) then pull latest cloud bookings for this user
                await storageController.syncNow();
                await storageController.syncBookingsFromCloud(removeMissingSynced: true);
              }
              _refreshBookings();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedBookings.length,
              itemBuilder: (context, index) {
                final booking = sortedBookings[index];
                return BookingHistoryCard(
                  booking: booking,
                  onDelete: () => _deleteBooking(booking.id),
                  onSync: () => _syncBooking(booking),
                  onStatusChanged: _refreshBookings,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/booking'),
        label: const Text('Booking Baru'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteBooking(String id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Booking?'),
        content: const Text('Apakah Anda yakin ingin menghapus booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await bookingController.deleteBooking(id);
      if (success) {
        _refreshBookings();
      }
    }
  }

  Future<void> _syncBooking(HiveBooking booking) async {
    if (!storageController.isOnline.value) {
      Get.snackbar(
        'Offline',
        'Tunggu hingga online untuk sinkronisasi',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await storageController.syncNow();
    _refreshBookings();
  }
}

class BookingHistoryCard extends StatelessWidget {
  final HiveBooking booking;
  final VoidCallback onDelete;
  final VoidCallback onSync;
  final VoidCallback onStatusChanged;

  const BookingHistoryCard({
    Key? key,
    required this.booking,
    required this.onDelete,
    required this.onSync,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.customerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: dateFormat.format(booking.bookingDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: booking.bookingTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildDetailItem(
              icon: Icons.location_on,
              label: 'Lokasi',
              value: booking.address,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.phone,
                    label: 'Telepon',
                    value: booking.phoneNumber,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.attach_money,
                    label: 'Harga',
                    value: 'Rp ${booking.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}')}',
                  ),
                ),
              ],
            ),
            
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            
            if (booking.photoUrls != null && booking.photoUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Foto (${booking.photoUrls!.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: booking.photoUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          booking.photoUrls![index],
                          fit: BoxFit.cover,
                          width: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!booking.synced)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSync,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Sinkronisasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.amber[800],
                      ),
                    ),
                  ),
              ],
            ),
            
            if (booking.status == 'pending') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateBookingStatus(booking.id, 'confirmed'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Tandai Dikonfirmasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green[800],
                  ),
                ),
              ),
            ],
            
            if (booking.status == 'confirmed') ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final ratingController = Get.find<RatingReviewController>();
                  final hasRating = ratingController.hasRatingForBooking(booking.id);
                  
                  if (hasRating) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Rating sudah diberikan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(context, booking),
                      icon: const Icon(Icons.star_rate, size: 18),
                      label: const Text('Berikan Rating & Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.amber[900],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    final storageController = Get.find<StorageController>();
    final booking = storageController.getBooking(bookingId);
    
    if (booking == null) return;
    
    try {
      booking.status = newStatus;
      booking.updatedAt = DateTime.now();
      
      // Save to Hive
      await storageController.hiveService.updateBooking(booking);
      
      // Sync to Supabase if authenticated and online
      if (storageController.isOnline.value && storageController.supabaseService.isAuthenticated) {
        await storageController.supabaseService.updateBookingStatus(bookingId, newStatus);
        print('[BookingHistoryCard] ✅ Booking status updated to Supabase: $bookingId -> $newStatus');
      }
      
      Get.snackbar(
        'Success',
        'Status booking diperbarui menjadi ${newStatus.toUpperCase()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green[800],
      );
      
      onStatusChanged();
    } catch (e) {
      print('[BookingHistoryCard] ❌ Error updating status: $e');
      Get.snackbar(
        'Error',
        'Gagal memperbarui status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showRatingDialog(BuildContext context, HiveBooking booking) {
    final ratingController = Get.find<RatingReviewController>();
    int selectedRating = 5;
    final reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Berikan Rating & Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Berikan Rating:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = star;
                        });
                      },
                      child: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '$selectedRating Bintang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tulis Review:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Bagaimana pengalaman Anda dengan layanan ini?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final review = reviewController.text.trim();
                if (review.isEmpty) {
                  Get.snackbar('Error', 'Review tidak boleh kosong');
                  return;
                }
                
                final success = await ratingController.createRatingReview(
                  bookingId: booking.id,
                  customerName: booking.customerName,
                  serviceName: booking.serviceName,
                  rating: selectedRating,
                  review: review,
                );
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  onStatusChanged(); // Refresh booking list
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
      case 'finished':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
      case 'finished':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
