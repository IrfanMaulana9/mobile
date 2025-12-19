import 'package:get/get.dart';
import '../models/payment.dart';
import '../services/xendit_service.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/storage_controller.dart';

/// Controller untuk Payment Management
class PaymentController extends GetxController {
  final xenditService = XenditService();
  late SupabaseService supabaseService;
  late AuthController authController;

  final payments = <Payment>[].obs;
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final currentPayment = Rxn<Payment>();

  @override
  Future<void> onInit() async {
    super.onInit();
    final storageController = Get.find<StorageController>();
    supabaseService = storageController.supabaseService;
    authController = Get.find<AuthController>();
    await loadPaymentHistory();
  }

  /// Create payment untuk booking
  Future<Payment?> createPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    if (!authController.isAuthenticated.value) {
      Get.snackbar('Error', 'Anda harus login terlebih dahulu');
      return null;
    }

    isProcessing.value = true;
    try {
      print('[PaymentController] 💳 Creating payment for booking: $bookingId');

      // Generate external ID untuk Xendit
      final externalId = 'booking_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Determine payment methods untuk Xendit
      List<String> xenditPaymentMethods = [];
      switch (paymentMethod) {
        case PaymentMethod.bankTransfer:
          xenditPaymentMethods = ['BANK_TRANSFER'];
          break;
        case PaymentMethod.qris:
          xenditPaymentMethods = ['QRIS'];
          break;
        case PaymentMethod.ovo:
        case PaymentMethod.dana:
        case PaymentMethod.linkaja:
        case PaymentMethod.shopeepay:
          xenditPaymentMethods = ['EWALLET'];
          break;
      }

      // Create invoice di Xendit
      final invoice = await xenditService.createInvoice(
        externalId: externalId,
        amount: amount,
        payerEmail: customerEmail,
        description: 'Pembayaran Cleaning Service - Booking $bookingId',
        customerName: customerName,
        customerPhoneNumber: customerPhone,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        paymentMethods: xenditPaymentMethods,
      );

      if (invoice == null) {
        Get.snackbar('Error', 'Gagal membuat invoice pembayaran');
        return null;
      }

      // Create payment record di database
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final payment = Payment(
        id: paymentId,
        bookingId: bookingId,
        userId: authController.currentUserId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: PaymentStatus.pending,
        xenditInvoiceId: invoice.id,
        paymentUrl: invoice.invoiceUrl,
        qrCode: invoice.qrCode?['qr_string']?.toString(),
        expiryDate: invoice.expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'external_id': externalId,
          'merchant_name': invoice.merchantName,
        },
      );

      // Save ke Supabase
      final savedPayment = await supabaseService.insertPayment(payment);
      if (savedPayment != null) {
        currentPayment.value = savedPayment;
        await loadPaymentHistory();
        print('[PaymentController] ✅ Payment created: $paymentId');
        return savedPayment;
      } else {
        Get.snackbar('Error', 'Gagal menyimpan data pembayaran');
        return null;
      }
    } catch (e) {
      print('[PaymentController] ❌ Error creating payment: $e');
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Check payment status dari Xendit
  Future<void> checkPaymentStatus(String paymentId) async {
    try {
      final payment = payments.firstWhere((p) => p.id == paymentId);
      if (payment.xenditInvoiceId == null) return;

      final invoice = await xenditService.getInvoiceStatus(payment.xenditInvoiceId!);
      if (invoice == null) return;

      PaymentStatus newStatus;
      switch (invoice.status.toUpperCase()) {
        case 'PAID':
          newStatus = PaymentStatus.paid;
          break;
        case 'EXPIRED':
          newStatus = PaymentStatus.expired;
          break;
        case 'FAILED':
          newStatus = PaymentStatus.failed;
          break;
        default:
          newStatus = PaymentStatus.pending;
      }

      // Update payment status
      if (newStatus != payment.status) {
        await supabaseService.updatePaymentStatus(
          paymentId,
          newStatus,
          paidAt: newStatus == PaymentStatus.paid ? DateTime.now() : null,
        );
        await loadPaymentHistory();
      }
    } catch (e) {
      print('[PaymentController] ❌ Error checking payment status: $e');
    }
  }

  /// Load payment history
  Future<void> loadPaymentHistory() async {
    isLoading.value = true;
    try {
      final data = await supabaseService.getPaymentHistory();
      payments.value = data.map((map) => Payment.fromMap(map)).toList();
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('[PaymentController] ✅ Loaded ${payments.length} payments');
    } catch (e) {
      print('[PaymentController] ❌ Error loading payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get payment by booking ID
  Payment? getPaymentByBookingId(String bookingId) {
    try {
      return payments.firstWhere((p) => p.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  /// Get payment by ID
  Payment? getPaymentById(String paymentId) {
    try {
      return payments.firstWhere((p) => p.id == paymentId);
    } catch (e) {
      return null;
    }
  }
}

