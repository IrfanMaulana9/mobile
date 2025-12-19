import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/payment.dart';

/// Service untuk Xendit Payment Gateway Integration
class XenditService {
  static final XenditService _instance = XenditService._internal();
  factory XenditService() => _instance;
  XenditService._internal();

  // Xendit API Configuration
  static const String _baseUrl = 'https://api.xendit.co';
  static const String _secretKey = 'xnd_development_kSUhoGBSqUseGpTkJ008PXBypPa8X0BKlRcDSxdxAMModGrl8mQVeKh08BczG';
  
  // Headers untuk Xendit API
  Map<String, String> get _headers {
    final credentials = '$_secretKey:';
    final bytes = utf8.encode(credentials);
    final base64Str = base64Encode(bytes);
    return {
      'Authorization': 'Basic $base64Str',
      'Content-Type': 'application/json',
    };
  }

  /// Create Xendit Invoice dengan multiple payment methods
  Future<XenditInvoiceResponse?> createInvoice({
    required String externalId,
    required double amount,
    required String payerEmail,
    required String description,
    String? customerName,
    String? customerPhoneNumber,
    DateTime? expiryDate,
    List<String>? paymentMethods, // ['BANK_TRANSFER', 'QRIS', 'EWALLET']
  }) async {
    try {
      print('[XenditService] 💳 Creating invoice...');
      print('[XenditService]    External ID: $externalId');
      print('[XenditService]    Amount: $amount');
      print('[XenditService]    Payer Email: $payerEmail');

      final invoiceData = {
        'external_id': externalId,
        'amount': amount,
        'payer_email': payerEmail,
        'description': description,
        if (customerName != null) 'customer': {
          'given_names': customerName,
          if (customerPhoneNumber != null) 'mobile_number': customerPhoneNumber,
        },
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
        if (paymentMethods != null && paymentMethods.isNotEmpty)
          'payment_methods': paymentMethods,
        'currency': 'IDR',
        'locale': 'id',
        'items': [
          {
            'name': description,
            'quantity': 1,
            'price': amount,
            'category': 'Cleaning Service',
          }
        ],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/invoices'),
        headers: _headers,
        body: jsonEncode(invoiceData),
      ).timeout(const Duration(seconds: 30));

      print('[XenditService] Response Status: ${response.statusCode}');
      print('[XenditService] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final invoice = XenditInvoiceResponse.fromJson(json);
        print('[XenditService] ✅ Invoice created: ${invoice.id}');
        return invoice;
      } else {
        print('[XenditService] ❌ Failed to create invoice: ${response.statusCode}');
        print('[XenditService] Error: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[XenditService] ❌ Exception creating invoice: $e');
      print('[XenditService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get invoice status dari Xendit
  Future<XenditInvoiceResponse?> getInvoiceStatus(String invoiceId) async {
    try {
      print('[XenditService] 🔍 Checking invoice status: $invoiceId');

      final response = await http.get(
        Uri.parse('$_baseUrl/v2/invoices/$invoiceId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final invoice = XenditInvoiceResponse.fromJson(json);
        print('[XenditService] ✅ Invoice status: ${invoice.status}');
        return invoice;
      } else {
        print('[XenditService] ❌ Failed to get invoice: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[XenditService] ❌ Exception getting invoice: $e');
      return null;
    }
  }

  /// Create QRIS Payment
  Future<Map<String, dynamic>?> createQRIS({
    required String externalId,
    required double amount,
    required String callbackUrl,
  }) async {
    try {
      print('[XenditService] 📱 Creating QRIS payment...');

      final qrisData = {
        'reference_id': externalId,
        'type': 'DYNAMIC',
        'currency': 'IDR',
        'amount': amount,
        'callback_url': callbackUrl,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/qr_codes'),
        headers: _headers,
        body: jsonEncode(qrisData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('[XenditService] ✅ QRIS created');
        return json;
      } else {
        print('[XenditService] ❌ Failed to create QRIS: ${response.statusCode}');
        print('[XenditService] Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[XenditService] ❌ Exception creating QRIS: $e');
      return null;
    }
  }

  /// Create Virtual Account (Bank Transfer)
  Future<Map<String, dynamic>?> createVirtualAccount({
    required String externalId,
    required String bankCode, // BCA, BNI, BRI, MANDIRI, etc.
    required String accountHolderName,
    required double amount,
  }) async {
    try {
      print('[XenditService] 🏦 Creating Virtual Account...');

      final vaData = {
        'external_id': externalId,
        'bank_code': bankCode,
        'name': accountHolderName,
        'expected_amount': amount,
        'is_closed': true,
        'expiration_date': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/virtual_accounts'),
        headers: _headers,
        body: jsonEncode(vaData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('[XenditService] ✅ Virtual Account created');
        return json;
      } else {
        print('[XenditService] ❌ Failed to create VA: ${response.statusCode}');
        print('[XenditService] Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[XenditService] ❌ Exception creating VA: $e');
      return null;
    }
  }

  /// Create E-Wallet Payment
  Future<Map<String, dynamic>?> createEWallet({
    required String externalId,
    required String channelCode, // OVO, DANA, LINKAJA, SHOPEEPAY
    required double amount,
    required String callbackUrl,
    Map<String, dynamic>? customer,
  }) async {
    try {
      print('[XenditService] 💰 Creating E-Wallet payment...');

      final ewalletData = {
        'reference_id': externalId,
        'currency': 'IDR',
        'amount': amount,
        'channel_code': channelCode,
        'channel_properties': {
          'success_redirect_url': callbackUrl,
          'failure_redirect_url': callbackUrl,
        },
        if (customer != null) 'customer': customer,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/ewallets/charges'),
        headers: _headers,
        body: jsonEncode(ewalletData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('[XenditService] ✅ E-Wallet charge created');
        return json;
      } else {
        print('[XenditService] ❌ Failed to create E-Wallet: ${response.statusCode}');
        print('[XenditService] Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[XenditService] ❌ Exception creating E-Wallet: $e');
      return null;
    }
  }

  /// Get payment status untuk E-Wallet
  Future<Map<String, dynamic>?> getEWalletStatus({
    required String chargeId,
  }) async {
    try {
      print('[XenditService] 🔍 Checking E-Wallet status: $chargeId');

      final response = await http.get(
        Uri.parse('$_baseUrl/ewallets/charges/$chargeId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('[XenditService] ✅ E-Wallet status retrieved');
        return json;
      } else {
        print('[XenditService] ❌ Failed to get E-Wallet status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[XenditService] ❌ Exception getting E-Wallet status: $e');
      return null;
    }
  }
}

