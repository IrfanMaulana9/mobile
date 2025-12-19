import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/qr_code_service.dart';
import '../models/qr_code_data.dart';

/// Widget untuk menampilkan QR Code dengan informasi lengkap
class QRCodeDisplay extends StatelessWidget {
  final QRCodeData qrData;
  final String title;
  final String? subtitle;
  final double qrSize;
  final bool showDownloadButton;
  final bool showShareButton;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const QRCodeDisplay({
    super.key,
    required this.qrData,
    required this.title,
    this.subtitle,
    this.qrSize = 250,
    this.showDownloadButton = true,
    this.showShareButton = true,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qrService = QRCodeService();

    Widget qrWidget;
    
    if (qrData.type == 'booking_confirmation') {
      qrWidget = qrService.generateBookingQRCode(
        bookingId: qrData.bookingId,
        customerName: qrData.customerName ?? '',
        serviceName: qrData.serviceName ?? '',
        totalPrice: qrData.totalPrice ?? 0,
        bookingDate: qrData.bookingDate ?? '',
        size: qrSize,
      );
    } else if (qrData.type == 'payment') {
      qrWidget = qrService.generatePaymentQRCode(
        bookingId: qrData.bookingId,
        amount: qrData.amount ?? 0,
        paymentMethod: qrData.paymentMethod ?? 'qris',
        size: qrSize,
      );
    } else {
      qrWidget = qrService.generateQRCodeFromString(
        data: qrData.toJsonString(),
        size: qrSize,
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 24),
            
            // QR Code
            Center(child: qrWidget),
            
            const SizedBox(height: 24),
            
            // QR Code Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    cs,
                    icon: Icons.qr_code,
                    label: 'Booking ID',
                    value: qrData.bookingId,
                  ),
                  if (qrData.customerName != null)
                    _buildInfoRow(
                      cs,
                      icon: Icons.person,
                      label: 'Customer',
                      value: qrData.customerName!,
                    ),
                  if (qrData.serviceName != null)
                    _buildInfoRow(
                      cs,
                      icon: Icons.cleaning_services,
                      label: 'Service',
                      value: qrData.serviceName!,
                    ),
                  if (qrData.totalPrice != null)
                    _buildInfoRow(
                      cs,
                      icon: Icons.attach_money,
                      label: 'Total',
                      value: 'Rp ${qrData.totalPrice!.toStringAsFixed(0)}',
                    ),
                  if (qrData.bookingDate != null)
                    _buildInfoRow(
                      cs,
                      icon: Icons.calendar_today,
                      label: 'Tanggal',
                      value: qrData.bookingDate!,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            if (showDownloadButton || showShareButton)
              Row(
                children: [
                  if (showDownloadButton)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDownload ?? () {
                          Get.snackbar(
                            'Info',
                            'Fitur download akan segera tersedia',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ),
                  if (showDownloadButton && showShareButton)
                    const SizedBox(width: 12),
                  if (showShareButton)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare ?? () {
                          Get.snackbar(
                            'Info',
                            'Fitur share akan segera tersedia',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

