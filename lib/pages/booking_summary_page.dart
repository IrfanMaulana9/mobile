import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io'; // ✅ IMPORT FILE
import '../controllers/booking_controller.dart';
import '../models/booking.dart';

class BookingSummaryPage extends StatefulWidget {
  const BookingSummaryPage({super.key});

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  final controller = Get.find<BookingController>();
  late Future<double> _etaFuture;

  @override
  void initState() {
    super.initState();
    _etaFuture = controller.getETA();
  }

  // ✅ METHOD BARU: Build image widget dari file path
  Widget _buildImageFromPath(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red),
            );
          },
        );
      } else {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.photo, color: Colors.grey),
        );
      }
    } catch (e) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final booking = controller.bookingData.value;
    final promo = booking.selectedPromotion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Booking'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periksa kembali detail sebelum konfirmasi booking',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Informasi Pemesan
            _buildSection(
              context,
              title: 'Informasi Pemesan',
              child: Column(
                children: [
                  _buildInfoTile(
                    cs,
                    icon: Icons.person,
                    label: 'Nama',
                    value: booking.customerName.isEmpty ? 'Belum diisi' : booking.customerName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    cs,
                    icon: Icons.phone,
                    label: 'Telepon',
                    value: booking.phoneNumber.isEmpty ? 'Belum diisi' : booking.phoneNumber,
                  ),
                  // ✅ TAMBAH NOTES DISPLAY
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoTile(
                      cs,
                      icon: Icons.note,
                      label: 'Catatan Khusus',
                      value: booking.notes!,
                    ),
                  ],
                ],
              ),
            ),
            
            // Layanan Dipilih
            _buildSection(
              context,
              title: 'Layanan Dipilih',
              child: booking.selectedService != null
                  ? _buildServiceDetail(cs, booking.selectedService!)
                  : Text('Belum dipilih', style: TextStyle(color: cs.error)),
            ),
            
            // Lokasi Tujuan
            _buildSection(
              context,
              title: 'Lokasi Tujuan',
              child: booking.location != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoTile(
                          cs,
                          icon: Icons.location_on,
                          label: 'Alamat',
                          value: booking.location!.address,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoTile(
                          cs,
                          icon: Icons.map,
                          label: 'Koordinat',
                          value:
                              '${booking.location!.latitude.toStringAsFixed(4)}, ${booking.location!.longitude.toStringAsFixed(4)}',
                        ),
                      ],
                    )
                  : Text('Belum dipilih', style: TextStyle(color: cs.error)),
            ),
            
            // ✅ SECTION BARU: Notes & Photos Preview
            if (booking.notes != null && booking.notes!.isNotEmpty || 
                controller.localPhotoPaths.isNotEmpty) 
              _buildSection(
                context,
                title: 'Informasi Tambahan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      _buildInfoTile(
                        cs,
                        icon: Icons.notes,
                        label: 'Catatan',
                        value: booking.notes!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (controller.localPhotoPaths.isNotEmpty) ...[
                      Text(
                        'Foto Pendukung (${controller.localPhotoPaths.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110, // ✅ TINGGI DIPERBESAR
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.localPhotoPaths.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              height: 100,
                              margin: EdgeInsets.only(
                                right: index == controller.localPhotoPaths.length - 1 ? 0 : 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cs.outline),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImageFromPath(controller.localPhotoPaths[index]), // ✅ PERBAIKAN DI SINI
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Foto akan diupload setelah booking dikonfirmasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            // Lokasi Penyedia (UMM)
            _buildSection(
              context,
              title: 'Lokasi Penyedia (UMM)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile(
                    cs,
                    icon: Icons.store,
                    label: 'Lokasi Bisnis',
                    value: BookingLocation.ummName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    cs,
                    icon: Icons.map,
                    label: 'Koordinat',
                    value:
                        '${BookingLocation.ummLat.toStringAsFixed(4)}, ${BookingLocation.ummLng.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),
            
            // Jadwal Booking
            _buildSection(
              context,
              title: 'Jadwal Booking',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile(
                    cs,
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: booking.bookingDate != null
                        ? '${booking.bookingDate!.day}/${booking.bookingDate!.month}/${booking.bookingDate!.year}'
                        : 'Belum dipilih',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    cs,
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: booking.bookingTime != null
                        ? '${booking.bookingTime!.hour.toString().padLeft(2, '0')}:${booking.bookingTime!.minute.toString().padLeft(2, '0')}'
                        : 'Belum dipilih',
                  ),
                ],
              ),
            ),
            
            // Cuaca Perkiraan
            Obx(() {
              if (controller.currentWeather.value != null) {
                final weather = controller.currentWeather.value;
                return _buildSection(
                  context,
                  title: 'Cuaca Perkiraan',
                  child: Column(
                    children: [
                      Card(
                        color: cs.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weather.getWeatherDescription(),
                                        style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${weather.temperature.toStringAsFixed(1)}°C, Kelembapan: ${weather.humidity.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Angin: ${weather.windSpeed.toStringAsFixed(1)} km/h',
                                        style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    weather.getWeatherIcon(),
                                    color: cs.onPrimaryContainer,
                                    size: 40,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  weather.getCleaningRecommendation(),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            // Estimasi Jarak & Waktu
            _buildSection(
              context,
              title: 'Estimasi Jarak & Waktu Tempuh',
              child: FutureBuilder<double>(
                future: _etaFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final distance =
                        booking.location?.distanceFromUMM() ?? 0.0;
                    return Column(
                      children: [
                        _buildInfoTile(
                          cs,
                          icon: Icons.straighten,
                          label: 'Jarak dari UMM',
                          value:
                              '${distance.toStringAsFixed(2)} km',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoTile(
                          cs,
                          icon: Icons.schedule,
                          label: 'Estimasi ETA',
                          value:
                              '${snapshot.data!.toStringAsFixed(0)} menit (~${(snapshot.data! / 60).toStringAsFixed(1)} jam)',
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            
            // Perhitungan Harga
            _buildSection(
              context,
              title: 'Perhitungan Harga',
              child: Column(
                children: [
                  _buildPriceTile(
                    cs,
                    label: 'Harga Layanan',
                    value: 'Rp${controller.getBasePrice().toStringAsFixed(0)}',
                    color: cs.onSurface,
                  ),
                  if (promo != null && booking.hasValidPromotion) ...[
                    const SizedBox(height: 8),
                    _buildPriceTile(
                      cs,
                      label: 'Diskon Promo (${promo.discountPercentage}%)',
                      value: '-Rp${controller.getPromoDiscount().toStringAsFixed(0)}',
                      color: Colors.red,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceTile(
                    cs,
                    label: 'Biaya Jarak (${(booking.location?.distanceFromUMM() ?? 0).toStringAsFixed(2)} km)',
                    value: 'Rp${controller.getDistanceFee().toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: cs.outline),
                  ),
                  _buildPriceTile(
                    cs,
                    label: 'Total Estimasi',
                    value: 'Rp${controller.calculateEstimatedPrice().toStringAsFixed(0)}',
                    color: cs.primary,
                    isBold: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFormValid(booking) ? () {
                  _submitBooking();
                } : null,
                icon: const Icon(Icons.check),
                label: const Text('Konfirmasi Booking'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
            
            if (!_isFormValid(booking))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Harap lengkapi semua data sebelum konfirmasi',
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _isFormValid(BookingData booking) {
    return booking.customerName.isNotEmpty &&
        booking.phoneNumber.isNotEmpty &&
        booking.selectedService != null &&
        booking.location != null &&
        booking.bookingDate != null &&
        booking.bookingTime != null;
  }

  Future<void> _submitBooking() async {
    final success = await controller.submitBooking();
    if (success) {
      final bookingId = controller.lastSubmittedBookingId.value;
      final customerName = controller.lastSubmittedCustomerName.value;
      
      // Show success snackbar
      Get.snackbar(
        'Success',
        'Booking berhasil dibuat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to booking confirmation page with QR Code after 1 second delay
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/booking-confirmation');
    }
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoTile(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTile(
    ColorScheme cs, {
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 14 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 16 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetail(ColorScheme cs, CleaningService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile(
          cs,
          icon: Icons.cleaning_services,
          label: 'Layanan',
          value: service.name,
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          cs,
          icon: Icons.description,
          label: 'Deskripsi',
          value: service.description,
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          cs,
          icon: Icons.schedule,
          label: 'Estimasi Durasi',
          value: '${service.estimatedHours} jam',
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          cs,
          icon: Icons.attach_money,
          label: 'Harga Dasar',
          value: 'Rp${service.price.toStringAsFixed(0)}',
        ),
      ],
    );
  }
}
