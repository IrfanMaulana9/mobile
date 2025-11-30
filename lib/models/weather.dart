import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final String weatherCode;
  final double humidity;
  final double windSpeed;
  final String location;
  final DateTime timestamp;
  final double rainProbability;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    required this.timestamp,
    this.rainProbability = 0.0,
  });

  String getCleaningRecommendation() {
    if (weatherCode == '0' || weatherCode == '1') {
      return '☀️ Cuaca cerah sempurna untuk layanan outdoor dan window cleaning. Pencahayaan optimal untuk hasil sempurna.';
    } else if (weatherCode == '2' || weatherCode == '3') {
      return '☁️ Cuaca berawan cocok untuk semua layanan indoor. Kelembapan sedang mendukung proses pengeringan.';
    } else if (weatherCode == '45' || weatherCode == '48') {
      return '🌫️ Berkabut - Prioritaskan layanan indoor. Visibility rendah membuat outdoor cleaning tidak ideal.';
    } else if (weatherCode == '51' || weatherCode == '53' || weatherCode == '55') {
      return '🌧️ Hujan ringan - Hindari outdoor dan window cleaning. Fokus pada laundry dan deep cleaning indoor. Hujan dapat berlanjut.';
    } else if (weatherCode == '61' || weatherCode == '63' || weatherCode == '65') {
      return '⛈️ Hujan lebat - Sangat tidak disarankan untuk outdoor. Tunda jadwal atau reschedule untuk keselamatan.';
    } else if (weatherCode == '71' || weatherCode == '73' || weatherCode == '75') {
      return '❄️ Kondisi salju - Layanan dibatasi dan memerlukan persiapan khusus. Hubungi kami untuk diskusi.';
    } else {
      return '⚠️ Kondisi cuaca ekstrem - Hubungi kami untuk konsultasi keamanan.';
    }
  }

  bool isWindSafe() {
    // Wind speed above 40 km/h is unsafe for outdoor cleaning
    return windSpeed < 40;
  }

  String getWindWarning() {
    if (windSpeed >= 40) {
      return '⚠️ Angin kencang (${windSpeed.toStringAsFixed(1)} km/h) - Tidak aman untuk outdoor dan window cleaning.';
    }
    return '';
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

  String getRecommendedServices() {
    if (weatherCode == '0' || weatherCode == '1') {
      return 'Outdoor Cleaning, Window Cleaning';
    } else if (weatherCode == '2' || weatherCode == '3') {
      return 'Deep Cleaning, Indoor Cleaning';
    } else if (rainProbability > 50) {
      return 'Indoor Cleaning, Laundry Service';
    } else {
      return 'Indoor Cleaning';
    }
  }
}
