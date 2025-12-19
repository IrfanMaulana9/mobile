import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/payment_controller.dart';
import '../models/payment.dart';
import '../controllers/auth_controller.dart';
import 'dart:async';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final paymentController = Get.put(PaymentController());
  final authController = Get.find<AuthController>();
  PaymentMethod? selectedMethod;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    // Check if payment already exists
    _checkExistingPayment();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _checkExistingPayment() {
    final existingPayment = paymentController.getPaymentByBookingId(widget.bookingId);
    if (existingPayment != null && existingPayment.canPay) {
      paymentController.currentPayment.value = existingPayment;
      _startStatusCheck(existingPayment.id);
    }
  }

  void _startStatusCheck(String paymentId) {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await paymentController.checkPaymentStatus(paymentId);
      final payment = paymentController.getPaymentById(paymentId);
      if (payment != null && payment.status != PaymentStatus.pending) {
        timer.cancel();
        if (payment.status == PaymentStatus.paid) {
          Get.snackbar(
            'Pembayaran Berhasil',
            'Pembayaran Anda telah dikonfirmasi',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            duration: const Duration(seconds: 3),
          );
          Get.back(result: true);
        }
      }
    });
  }

  Future<void> _processPayment() async {
    if (selectedMethod == null) {
      Get.snackbar('Error', 'Pilih metode pembayaran terlebih dahulu');
      return;
    }

    final payment = await paymentController.createPayment(
      bookingId: widget.bookingId,
      amount: widget.amount,
      paymentMethod: selectedMethod!,
      customerName: widget.customerName,
      customerEmail: widget.customerEmail,
      customerPhone: widget.customerPhone,
    );

    if (payment != null && payment.paymentUrl != null) {
      _startStatusCheck(payment.id);
      // Open payment URL
      final uri = Uri.parse(payment.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Tidak dapat membuka halaman pembayaran');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Obx(() {
        final currentPayment = paymentController.currentPayment.value;
        
        if (currentPayment != null && currentPayment.canPay) {
          return _buildPaymentInProgress(context, currentPayment, cs);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                          Text(
                            'Rp${widget.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods
              Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Bank Transfer
              _buildPaymentMethodCard(
                context,
                PaymentMethod.bankTransfer,
                'Transfer Bank',
                'BCA, BNI, BRI, Mandiri',
                cs,
              ),
              const SizedBox(height: 12),

              // QRIS
              _buildPaymentMethodCard(
                context,
                PaymentMethod.qris,
                'QRIS',
                'Scan QR Code untuk pembayaran',
                cs,
              ),
              const SizedBox(height: 12),

              // E-Wallet Section
              Text(
                'E-Wallet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              _buildPaymentMethodCard(
                context,
                PaymentMethod.ovo,
                'OVO',
                'Bayar dengan OVO',
                cs,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethodCard(
                context,
                PaymentMethod.dana,
                'DANA',
                'Bayar dengan DANA',
                cs,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethodCard(
                context,
                PaymentMethod.linkaja,
                'LinkAja',
                'Bayar dengan LinkAja',
                cs,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethodCard(
                context,
                PaymentMethod.shopeepay,
                'ShopeePay',
                'Bayar dengan ShopeePay',
                cs,
              ),

              const SizedBox(height: 24),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: paymentController.isProcessing.value
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: paymentController.isProcessing.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lanjutkan Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PaymentMethod method,
    String title,
    String subtitle,
    ColorScheme cs,
  ) {
    final isSelected = selectedMethod == method;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? cs.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method.icon,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: cs.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInProgress(
    BuildContext context,
    Payment payment,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Payment Info Card
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pembayaran Sedang Diproses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp${payment.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      payment.status.displayName,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // QR Code (if available)
          if (payment.qrCode != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code untuk pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        payment.qrCode!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Payment URL Button
          if (payment.paymentUrl != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(payment.paymentUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Halaman Pembayaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Status Check Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Status pembayaran akan diperiksa otomatis. Pastikan Anda telah menyelesaikan pembayaran.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Check Status Button
          OutlinedButton.icon(
            onPressed: () => paymentController.checkPaymentStatus(payment.id),
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Status Pembayaran'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

