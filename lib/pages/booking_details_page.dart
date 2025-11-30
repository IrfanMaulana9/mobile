import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../controllers/storage_controller.dart';
import 'notes_page.dart';

class BookingDetailsPage extends StatefulWidget {
  static const String routeName = '/booking-details';
  
  final String bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late StorageController storageController;
  
  @override
  void initState() {
    super.initState();
    storageController = Get.find<StorageController>();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final booking = storageController.getBooking(widget.bookingId);
    
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Booking'),
          backgroundColor: cs.primary,
        ),
        body: const Center(
          child: Text('Booking tidak ditemukan'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'Informasi Pemesan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Nama', booking.customerName),
                  const SizedBox(height: 8),
                  _buildInfoRow('Telepon', booking.phoneNumber),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Catatan', booking.notes!),
                  ],
                ],
              ),
            ),
            
            _buildSection(
              context,
              title: 'Layanan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Nama Layanan', booking.serviceName),
                  const SizedBox(height: 8),
                  _buildInfoRow('Harga', 'Rp${booking.totalPrice.toStringAsFixed(0)}'),
                ],
              ),
            ),
            
            _buildSection(
              context,
              title: 'Lokasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Alamat', booking.address),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Koordinat',
                    '${booking.latitude.toStringAsFixed(4)}, ${booking.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),
            
            _buildSection(
              context,
              title: 'Jadwal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Tanggal',
                    '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Waktu', booking.bookingTime),
                ],
              ),
            ),
            
            _buildSection(
              context,
              title: 'Status',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.note_add),
                label: const Text('Kelola Catatan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
