/// Payment models untuk Xendit integration

enum PaymentMethod {
  bankTransfer('Bank Transfer', 'BANK_TRANSFER', Icons.account_balance),
  qris('QRIS', 'QRIS', Icons.qr_code),
  ovo('OVO', 'OVO', Icons.account_balance_wallet),
  dana('DANA', 'DANA', Icons.account_balance_wallet),
  linkaja('LinkAja', 'LINKAJA', Icons.account_balance_wallet),
  shopeepay('ShopeePay', 'SHOPEEPAY', Icons.account_balance_wallet);

  final String displayName;
  final String xenditCode;
  final IconData icon;

  const PaymentMethod(this.displayName, this.xenditCode, this.icon);
}

enum PaymentStatus {
  pending('pending', 'Menunggu Pembayaran'),
  paid('paid', 'Sudah Dibayar'),
  expired('expired', 'Kedaluwarsa'),
  failed('failed', 'Gagal'),
  cancelled('cancelled', 'Dibatalkan');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String? xenditInvoiceId;
  final String? xenditPaymentId;
  final String? paymentUrl;
  final String? qrCode;
  final DateTime? expiryDate;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.xenditInvoiceId,
    this.xenditPaymentId,
    this.paymentUrl,
    this.qrCode,
    this.expiryDate,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod.xenditCode,
      'status': status.value,
      'xendit_invoice_id': xenditInvoiceId,
      'xendit_payment_id': xenditPaymentId,
      'payment_url': paymentUrl,
      'qr_code': qrCode,
      'expiry_date': expiryDate?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: _parsePaymentMethod(map['payment_method']?.toString()),
      status: PaymentStatus.fromString(map['status']?.toString()),
      xenditInvoiceId: map['xendit_invoice_id']?.toString(),
      xenditPaymentId: map['xendit_payment_id']?.toString(),
      paymentUrl: map['payment_url']?.toString(),
      qrCode: map['qr_code']?.toString(),
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'].toString())
          : null,
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'].toString())
          : null,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['created_at'] ?? DateTime.now()),
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : (map['updated_at'] ?? DateTime.now()),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  static PaymentMethod _parsePaymentMethod(String? value) {
    if (value == null) return PaymentMethod.bankTransfer;
    return PaymentMethod.values.firstWhere(
      (e) => e.xenditCode == value,
      orElse: () => PaymentMethod.bankTransfer,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get canPay => status == PaymentStatus.pending && !isExpired;
}

class XenditInvoiceResponse {
  final String id;
  final String externalId;
  final String userId;
  final String status;
  final String merchantName;
  final double amount;
  final String invoiceUrl;
  final DateTime expiryDate;
  final Map<String, dynamic>? availableBanks;
  final Map<String, dynamic>? availableRetailOutlets;
  final Map<String, dynamic>? availableEwallets;
  final Map<String, dynamic>? qrCode;

  XenditInvoiceResponse({
    required this.id,
    required this.externalId,
    required this.userId,
    required this.status,
    required this.merchantName,
    required this.amount,
    required this.invoiceUrl,
    required this.expiryDate,
    this.availableBanks,
    this.availableRetailOutlets,
    this.availableEwallets,
    this.qrCode,
  });

  factory XenditInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return XenditInvoiceResponse(
      id: json['id']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      merchantName: json['merchant_name']?.toString() ?? 'CleanServ',
      amount: (json['amount'] ?? 0.0).toDouble(),
      invoiceUrl: json['invoice_url']?.toString() ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : DateTime.now().add(const Duration(days: 1)),
      availableBanks: json['available_banks'] != null
          ? Map<String, dynamic>.from(json['available_banks'])
          : null,
      availableRetailOutlets: json['available_retail_outlets'] != null
          ? Map<String, dynamic>.from(json['available_retail_outlets'])
          : null,
      availableEwallets: json['available_ewallets'] != null
          ? Map<String, dynamic>.from(json['available_ewallets'])
          : null,
      qrCode: json['qr_code'] != null
          ? Map<String, dynamic>.from(json['qr_code'])
          : null,
    );
  }
}

