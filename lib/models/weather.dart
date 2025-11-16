import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final String weatherCode;
  final double humidity;
  final double windSpeed;
  final String location;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    required this.timestamp,
  });

  String getCleaningRecommendation() {
    if (weatherCode == '0' || weatherCode == '1') {
      return 'Cuaca cerah - Sempurna untuk cuci karpet & sofa outdoor!';
    } else if (weatherCode == '2' || weatherCode == '3') {
      return 'Cuaca berawan - Cocok untuk pel lantai & cat dinding indoor.';
    } else if (weatherCode == '45' || weatherCode == '48') {
      return 'Berkabut - Tunda aktivitas outdoor, fokus indoor cleaning.';
    } else if (weatherCode == '51' || weatherCode == '53' || weatherCode == '55') {
      return 'Hujan ringan - Hindari outdoor, prioritaskan laundry & indoor service.';
    } else if (weatherCode == '61' || weatherCode == '63' || weatherCode == '65') {
      return 'Hujan lebat - Tunda semua aktivitas outdoor, fokus indoor.';
    } else if (weatherCode == '71' || weatherCode == '73' || weatherCode == '75') {
      return 'Salju - Layanan dibatasi, hubungi untuk jadwal khusus.';
    } else {
      return 'Cuaca ekstrem - Hubungi kami untuk konsultasi.';
    }
  }

  String getWeatherDescription() {
    switch (weatherCode) {
      case '0':
        return 'Cerah';
      case '1':
        return 'Sebagian Berawan';
      case '2':
        return 'Berawan';
      case '3':
        return 'Mendung';
      case '45':
      case '48':
        return 'Berkabut';
      case '51':
      case '53':
      case '55':
        return 'Hujan Ringan';
      case '61':
      case '63':
      case '65':
        return 'Hujan Lebat';
      case '71':
      case '73':
      case '75':
        return 'Salju';
      default:
        return 'Tidak Diketahui';
    }
  }

  IconData getWeatherIcon() {
    switch (weatherCode) {
      case '0':
        return Icons.wb_sunny;
      case '1':
      case '2':
        return Icons.wb_cloudy;
      case '3':
        return Icons.cloud;
      case '45':
      case '48':
        return Icons.cloud_queue;
      case '51':
      case '53':
      case '55':
        return Icons.grain;
      case '61':
      case '63':
      case '65':
        return Icons.cloud_download;
      case '71':
      case '73':
      case '75':
        return Icons.ac_unit;
      default:
        return Icons.help;
    }
  }
}
