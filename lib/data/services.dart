// Ganti: Icons.mop  -> Icons.cleaning_services
// Ganti: Icons.carpet -> Icons.layers (atau Icons.texture)
import 'package:flutter/material.dart';
import '../models/service.dart';

const layanan = <Service>[
  Service(nama: 'Pel Lantai', ikon: Icons.cleaning_services, warna: Colors.teal),
  Service(nama: 'Cuci Karpet', ikon: Icons.layers, warna: Colors.orange),
  Service(nama: 'Cuci Sofa', ikon: Icons.event_seat, warna: Colors.indigo),
  Service(nama: 'Laundry', ikon: Icons.local_laundry_service, warna: Colors.green),
  Service(nama: 'Cat Dinding', ikon: Icons.format_paint, warna: Colors.purple),
  Service(nama: 'Angkut Sampah', ikon: Icons.delete_sweep, warna: Colors.red),
];
