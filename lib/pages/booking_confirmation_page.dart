import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/booking_controller.dart';
import '../models/qr_code_data.dart';
import '../widgets/qr_code_display.dart';
import 'booking_history_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  static const String routeName = '/booking-confirmation';

  const BookingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = Get.find<BookingController>();

    final bookingId = controller.lastSubmittedBookingId.value;
    final customerName = controller.lastSubmittedCustomerName.value;
    final serviceName = controller.lastSubmittedServiceName.value;
    final totalPrice = controller.lastSubmittedTotalPrice.value;

    if (bookingId.isEmpty) {
      // If no booking data, redirect to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/');
      });
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    // Generate QR Code data
    final qrData = QRCodeData.bookingConfirmation(
      bookingId: bookingId,
      customerName: customerName,
      serviceName: serviceName,
      totalPrice: totalPrice,
      bookingDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Booking'),
        centerTitle: true,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 50,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Success Message
            Text(
              'Booking Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Booking Anda telah berhasil dibuat',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // QR Code Display
            QRCodeDisplay(
              qrData: qrData,
              title: 'QR Code Booking',
              subtitle: 'Scan QR Code ini untuk verifikasi booking',
              qrSize: 250,
              showDownloadButton: true,
              showShareButton: true,
            ),
            
            const SizedBox(height: 24),
            
            // Booking Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      cs,
                      icon: Icons.confirmation_number,
                      label: 'Booking ID',
                      value: bookingId,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      cs,
                      icon: Icons.person,
                      label: 'Customer',
                      value: customerName,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      cs,
                      icon: Icons.cleaning_services,
                      label: 'Service',
                      value: serviceName,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      cs,
                      icon: Icons.attach_money,
                      label: 'Total Harga',
                      value: 'Rp ${totalPrice.toStringAsFixed(0)}',
                      valueColor: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Simpan QR Code ini untuk verifikasi booking. Anda juga dapat melihat booking di halaman Riwayat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.offAllNamed(BookingHistoryPage.routeName);
                },
                icon: const Icon(Icons.history),
                label: const Text('Lihat Riwayat Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.offAllNamed('/');
                },
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Beranda'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

