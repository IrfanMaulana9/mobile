import 'dart:math';
import 'package:flutter/material.dart';
import 'promotion.dart';

class BookingLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? placeName;

  // Universitas Muhammadiyah Malang coordinates (provider base)
  static const double ummLat = -7.9799;
  static const double ummLng = 112.6328;
  static const String ummName = 'Universitas Muhammadiyah Malang';

  BookingLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.placeName,
  });

  double distanceFromUMM() {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(ummLat - latitude);
    final dLng = _toRadians(ummLng - longitude);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(latitude)) * cos(_toRadians(ummLat)) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double calculateETA({double speedKmPerHour = 40}) {
    final distance = distanceFromUMM();
    return (distance / speedKmPerHour) * 60; // returns minutes
  }

  double calculateDistanceFee() {
    final eta = calculateETA();
    
    if (eta > 200) {
      // Pesanan terlalu jauh - marked as invalid
      return -1;
    } else if (eta >= 150) {
      // 150-200 menit: Rp 10.000
      return 10000;
    } else if (eta >= 45) {
      // 45-150 menit: Rp 5.000
      return 5000;
    } else {
      // Dibawah 45 menit: Gratis
      return 0;
    }
  }

  String getDistanceFeeDescription() {
    final eta = calculateETA();
    
    if (eta > 200) {
      return 'Pesanan terlalu jauh (ETA > 200 menit)';
    } else if (eta >= 150) {
      return 'Rp 10.000 (ETA 150-200 menit)';
    } else if (eta >= 45) {
      return 'Rp 5.000 (ETA 45-150 menit)';
    } else {
      return 'Gratis (ETA < 45 menit)';
    }
  }

  bool isTooFar() {
    final eta = calculateETA();
    return eta > 200;
  }

  double _toRadians(double degree) => degree * (pi / 180);
}

class CleaningService {
  final String id;
  final String name;
  final String description;
  final double price;
  final String type; // 'indoor', 'outdoor', 'deep', 'window'
  final int estimatedHours;

  CleaningService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.estimatedHours,
  });
}

class BookingData {
  String customerName;
  String phoneNumber;
  CleaningService? selectedService;
  Promotion? selectedPromotion;
  BookingLocation? location;
  DateTime? bookingDate;
  TimeOfDay? bookingTime;
  String? notes;

  BookingData({
    this.customerName = '',
    this.phoneNumber = '',
    this.selectedService,
    this.selectedPromotion,
    this.location,
    this.bookingDate,
    this.bookingTime,
    this.notes,
  });

  bool _promotionMatchesService(Promotion promo, CleaningService service) {
    final a = promo.serviceName.trim().toLowerCase();
    final b = service.name.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  bool get hasValidPromotion {
    final promo = selectedPromotion;
    final service = selectedService;
    if (promo == null || service == null) return false;
    if (!promo.isActive) return false;
    return _promotionMatchesService(promo, service);
  }

  double get baseServicePrice => selectedService?.price ?? 0;

  double get discountedServicePrice {
    final base = baseServicePrice;
    if (!hasValidPromotion) return base;

    final promo = selectedPromotion!;
    // Prefer explicit promo price when it's meaningfully lower than base.
    if (promo.promoPrice > 0 && promo.promoPrice < base) {
      return promo.promoPrice;
    }
    // Fallback to percentage discount.
    final discounted = base * (1 - (promo.discountPercentage / 100));
    return discounted < base ? discounted : base;
  }

  double get promoDiscountAmount {
    final discount = baseServicePrice - discountedServicePrice;
    return discount > 0 ? discount : 0;
  }

  double calculateTotalPrice() {
    double basePrice = discountedServicePrice;
    double distanceFee = location?.calculateDistanceFee() ?? 0;
    
    // If fee is -1, it means order is too far
    if (distanceFee == -1) return 0;
    
    return basePrice + distanceFee;
  }

  bool isValidBookingTime() {
    if (bookingTime == null) return false;
    final h = bookingTime!.hour;
    final m = bookingTime!.minute;

    // Allowed range: 08:00 - 20:00 (inclusive, but not beyond 20:00)
    if (h < 8) return false;
    if (h > 20) return false;
    if (h == 20 && m > 0) return false;
    return true;
  }

  String getBookingTimeError() {
    if (bookingTime == null) return 'Pilih waktu booking';
    if (!isValidBookingTime()) {
      return 'Booking hanya tersedia jam 08:00 - 20:00. Silakan pilih waktu dalam rentang tersebut.';
    }
    return '';
  }
}
