import 'package:flutter/material.dart';

class Service {
  final String nama;
  final IconData ikon;
  final Color warna;
  final String deskripsi;
  
  const Service({
    required this.nama,
    required this.ikon,
    required this.warna,
    this.deskripsi = '',
  });
}
