import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_code_data.dart';

/// Service untuk generate dan manage QR Code
class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  /// Generate QR Code widget untuk booking confirmation
  Widget generateBookingQRCode({
    required String bookingId,
    required String customerName,
    required String serviceName,
    required double totalPrice,
    required String bookingDate,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final qrData = QRCodeData.bookingConfirmation(
      bookingId: bookingId,
      customerName: customerName,
      serviceName: serviceName,
      totalPrice: totalPrice,
      bookingDate: bookingDate,
    );

    return _buildQRWidget(
      data: qrData.toJsonString(),
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
    );
  }

  /// Generate QR Code widget untuk payment
  Widget generatePaymentQRCode({
    required String bookingId,
    required double amount,
    String paymentMethod = 'qris',
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final qrData = QRCodeData.payment(
      bookingId: bookingId,
      amount: amount,
      paymentMethod: paymentMethod,
    );

    return _buildQRWidget(
      data: qrData.toJsonString(),
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
    );
  }

  /// Generate QR Code widget dari data string
  Widget generateQRCodeFromString({
    required String data,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    String? errorCorrectionLevel, // 'L', 'M', 'Q', 'H'
  }) {
    return _buildQRWidget(
      data: data,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      errorCorrectionLevel: errorCorrectionLevel,
    );
  }

  /// Build QR Code widget dengan custom styling
  Widget _buildQRWidget({
    required String data,
    required double size,
    required Color foregroundColor,
    required Color backgroundColor,
    String? errorCorrectionLevel,
  }) {
    QrErrorCorrectLevel errorLevel = QrErrorCorrectLevel.M;
    
    if (errorCorrectionLevel != null) {
      switch (errorCorrectionLevel.toUpperCase()) {
        case 'L':
          errorLevel = QrErrorCorrectLevel.L;
          break;
        case 'M':
          errorLevel = QrErrorCorrectLevel.M;
          break;
        case 'Q':
          errorLevel = QrErrorCorrectLevel.Q;
          break;
        case 'H':
          errorLevel = QrErrorCorrectLevel.H;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foregroundColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        errorCorrectionLevel: errorLevel,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  /// Parse QR Code data dari string
  QRCodeData? parseQRCodeData(String qrString) {
    try {
      return QRCodeData.fromJsonString(qrString);
    } catch (e) {
      print('[QRCodeService] ❌ Failed to parse QR Code: $e');
      return null;
    }
  }

  /// Validate QR Code data
  bool isValidQRCodeData(String qrString) {
    try {
      final data = QRCodeData.fromJsonString(qrString);
      return data.type.isNotEmpty && data.bookingId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

