import 'package:flutter/material.dart';

class Promotion {
  final String id;
  final String title;
  final String description;
  final String serviceName;
  final double originalPrice;
  final double promoPrice;
  final int discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final String badge; // e.g., "Flash Sale", "Limited Time", "New"
  final IconData icon;
  final Color color;
  final List<String> terms; // Terms and conditions

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.serviceName,
    required this.originalPrice,
    required this.promoPrice,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.badge,
    required this.icon,
    required this.color,
    this.terms = const [],
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }
}
