import 'package:flutter/material.dart';
import '../models/service.dart';

const layanan = <Service>[
  Service(
    nama: 'Indoor Cleaning',
    ikon: Icons.home,
    warna: Color(0xFF1AA5D4),
    deskripsi: 'Pembersihan ruangan dalam kos',
  ),
  Service(
    nama: 'Outdoor Cleaning',
    ikon: Icons.park,
    warna: Color(0xFFFF9C42),
    deskripsi: 'Pembersihan halaman dan area luar',
  ),
  Service(
    nama: 'Deep Cleaning',
    ikon: Icons.spa,
    warna: Color(0xFF6C5FE8),
    deskripsi: 'Pembersihan menyeluruh dan mendalam',
  ),
  Service(
    nama: 'Window Cleaning',
    ikon: Icons.window,
    warna: Color(0xFF0FA3B1),
    deskripsi: 'Pembersihan jendela dan kaca profesional',
  ),
];
