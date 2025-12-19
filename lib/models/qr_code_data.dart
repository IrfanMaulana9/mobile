import 'dart:convert';

/// Model untuk data QR Code
class QRCodeData {
  final String type; // 'booking_confirmation' | 'payment'
  final String bookingId;
  final String? customerName;
  final String? serviceName;
  final double? totalPrice;
  final String? bookingDate;
  final String? timestamp;
  final double? amount; // For payment
  final String? paymentMethod; // For payment

  QRCodeData({
    required this.type,
    required this.bookingId,
    this.customerName,
    this.serviceName,
    this.totalPrice,
    this.bookingDate,
    this.timestamp,
    this.amount,
    this.paymentMethod,
  });

  /// Create QR Code data for booking confirmation
  factory QRCodeData.bookingConfirmation({
    required String bookingId,
    required String customerName,
    required String serviceName,
    required double totalPrice,
    required String bookingDate,
  }) {
    return QRCodeData(
      type: 'booking_confirmation',
      bookingId: bookingId,
      customerName: customerName,
      serviceName: serviceName,
      totalPrice: totalPrice,
      bookingDate: bookingDate,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Create QR Code data for payment
  factory QRCodeData.payment({
    required String bookingId,
    required double amount,
    String paymentMethod = 'qris',
  }) {
    return QRCodeData(
      type: 'payment',
      bookingId: bookingId,
      amount: amount,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Convert to JSON string for QR Code
  String toJsonString() {
    final map = <String, dynamic>{
      'type': type,
      'booking_id': bookingId,
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
    };

    if (customerName != null) map['customer_name'] = customerName;
    if (serviceName != null) map['service_name'] = serviceName;
    if (totalPrice != null) map['total_price'] = totalPrice;
    if (bookingDate != null) map['booking_date'] = bookingDate;
    if (amount != null) map['amount'] = amount;
    if (paymentMethod != null) map['payment_method'] = paymentMethod;

    return jsonEncode(map);
  }

  /// Parse from JSON string
  factory QRCodeData.fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return QRCodeData(
        type: map['type'] as String? ?? '',
        bookingId: map['booking_id'] as String? ?? '',
        customerName: map['customer_name'] as String?,
        serviceName: map['service_name'] as String?,
        totalPrice: (map['total_price'] as num?)?.toDouble(),
        bookingDate: map['booking_date'] as String?,
        timestamp: map['timestamp'] as String?,
        amount: (map['amount'] as num?)?.toDouble(),
        paymentMethod: map['payment_method'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to parse QR Code data: $e');
    }
  }

  /// Convert to Map for easy access
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'booking_id': bookingId,
      'customer_name': customerName,
      'service_name': serviceName,
      'total_price': totalPrice,
      'booking_date': bookingDate,
      'timestamp': timestamp,
      'amount': amount,
      'payment_method': paymentMethod,
    };
  }
}

