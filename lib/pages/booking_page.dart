import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../models/booking.dart';
import 'booking_summary_page.dart';
import 'booking_location_map.dart';
import '../widgets/notes_photo_section.dart'; // ✅ IMPORT BARU
import '../data/promotions.dart';
import '../models/promotion.dart';

class BookingPage extends StatefulWidget {
  static const String routeName = '/booking';

  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final controller = Get.put(BookingController());
  late PageController _pageController;
  int _currentPage = 0;
  bool _skipServiceStep = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialArgsIfAny();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyInitialArgsIfAny() {
    try {
      final args = Get.arguments;
      if (args is! Map) return;

      final promoId = args['promoId']?.toString();
      final serviceName = args['serviceName']?.toString();
      final serviceType = args['serviceType']?.toString();

      CleaningService? serviceToSelect;

      if (serviceType != null && serviceType.isNotEmpty) {
        serviceToSelect = controller.availableServices
            .where((s) => s.type.toLowerCase() == serviceType.toLowerCase())
            .cast<CleaningService?>()
            .firstWhere((_) => true, orElse: () => null);
      }

      if (serviceToSelect == null && serviceName != null && serviceName.isNotEmpty) {
        serviceToSelect = controller.availableServices
            .where((s) => s.name.toLowerCase().contains(serviceName.toLowerCase()) || serviceName.toLowerCase().contains(s.name.toLowerCase()))
            .cast<CleaningService?>()
            .firstWhere((_) => true, orElse: () => null);
      }

      Promotion? promoToApply;
      if (promoId != null && promoId.isNotEmpty) {
        promoToApply = promotions
            .where((p) => p.id == promoId)
            .cast<Promotion?>()
            .firstWhere((_) => true, orElse: () => null);
      }

      // If promo exists but service not specified, try infer service from promo
      if (serviceToSelect == null && promoToApply != null) {
        final promoServiceName = promoToApply.serviceName.toLowerCase();
        serviceToSelect = controller.availableServices
            .where((s) {
              final serviceLower = s.name.toLowerCase();
              return serviceLower.contains(promoServiceName) || promoServiceName.contains(serviceLower);
            })
            .cast<CleaningService?>()
            .firstWhere((_) => true, orElse: () => null);
      }

      if (serviceToSelect != null) {
        controller.selectService(serviceToSelect);
        // If service comes from Beranda/Promo, skip the "Pilih Layanan" step.
        setState(() => _skipServiceStep = true);
      }

      if (promoToApply != null) {
        controller.applyPromotion(promoToApply);
      }
    } catch (e) {
      // ignore
      print('[BookingPage] Failed to apply initial args: $e');
    }
  }

  int get _stepCount => _skipServiceStep ? 4 : 5;

  void _nextPage() {
    if (_currentPage < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openMapPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationMapPicker(
          onLocationSelected: (lat, lng, address) {
            controller.setLocation(lat, lng, address);
            controller.loadWeatherForLocation(lat, lng);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Layanan Kebersihan'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          // Progress indicator - UBAH DARI 4 KE 5 STEP
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_stepCount, (index) {
                final isActive = index <= _currentPage;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive ? cs.primary : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildCustomerInfoPage(cs),
                if (!_skipServiceStep) _buildServiceSelectionPage(cs),
                _buildLocationPage(cs),
                _buildNotesPhotosPage(cs),
                _buildDateTimePage(cs),
              ],
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: cs.onSecondary,
                  ),
                ),
                
                if (_currentPage == _stepCount - 1)
                  ElevatedButton.icon(
                    onPressed: _validateAndProceed,
                    icon: const Icon(Icons.check),
                    label: const Text('Lanjut ke Ringkasan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lanjut'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndProceed() {
    final bookingData = controller.bookingData.value;
    
    if (!bookingData.isValidBookingTime()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingData.getBookingTimeError()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookingSummaryPage(),
      ),
    );
  }

  Widget _buildCustomerInfoPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pemesan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'Isi data diri Anda untuk proses booking',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 16),

          // If service is pre-selected from Beranda/Promo, show it here so user doesn't need service step.
          if (_skipServiceStep && controller.bookingData.value.selectedService != null) ...[
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layanan dipilih dari Beranda/Promo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.bookingData.value.selectedService!.name,
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Promo selector (so even when skipping service step, promo can still be chosen)
            Obx(() {
              final selectedService = controller.bookingData.value.selectedService;
              if (selectedService == null) return const SizedBox.shrink();

              final promos = controller.getActivePromotionsForSelectedService();
              final selectedPromo = controller.bookingData.value.selectedPromotion;

              return Card(
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Pilih Promo',
                            style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (promos.isEmpty)
                        Text(
                          'Tidak ada promo aktif untuk layanan ini.',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: promos.map((promo) {
                            final isActive = selectedPromo?.id == promo.id;
                            return ChoiceChip(
                              selected: isActive,
                              label: Text('${promo.title} (-${promo.discountPercentage}%)'),
                              onSelected: (selected) {
                                controller.applyPromotion(selected ? promo : null);
                              },
                              selectedColor: promo.color.withValues(alpha: 0.2),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          
          Card(
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: controller.setCustomerName,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  TextField(
                    onChanged: controller.setPhoneNumber,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Layanan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'Pilih layanan yang sesuai dengan kebutuhan Anda',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Obx(() {
            return Column(
              children: controller.availableServices.map((service) {
                final isSelected = controller.bookingData.value.selectedService?.id == service.id;
                return Card(
                  color: isSelected ? cs.primaryContainer : cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      onTap: () => controller.selectService(service),
                      leading: Icon(
                        _getServiceIcon(service.type),
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                        size: 28,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: TextStyle(
                                color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary : cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${service.estimatedHours}h',
                              style: TextStyle(
                                color: isSelected ? cs.onPrimary : cs.onSecondaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        service.description,
                        style: TextStyle(
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                      ),
                      trailing: Text(
                        'Rp${service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSelected ? cs.onPrimaryContainer : cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 16),

          // Promo selector for the selected service
          Obx(() {
            final selectedService = controller.bookingData.value.selectedService;
            if (selectedService == null) return const SizedBox.shrink();

            final promos = controller.getActivePromotionsForSelectedService();
            final selectedPromo = controller.bookingData.value.selectedPromotion;

            return Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_offer, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Promo untuk ${selectedService.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (promos.isEmpty)
                      Text(
                        'Belum ada promo aktif untuk layanan ini.',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: promos.map((promo) {
                          final isActive = selectedPromo?.id == promo.id;
                          return ChoiceChip(
                            selected: isActive,
                            label: Text('${promo.title} (-${promo.discountPercentage}%)'),
                            onSelected: (selected) {
                              controller.applyPromotion(selected ? promo : null);
                            },
                            selectedColor: promo.color.withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),
                    if (selectedPromo != null && controller.bookingData.value.hasValidPromotion) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Promo dipakai: ${selectedPromo.title}',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.applyPromotion(null),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Pembersihan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Obx(() {
            final location = controller.selectedLocation.value;
            
            if (location != null) {
              return Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Lokasi Dipilih',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        location.address,
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: cs.onPrimaryContainer.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jarak: ${location.distanceFromUMM().toStringAsFixed(2)} km',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Card(
              color: cs.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada lokasi dipilih',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map),
              label: Obx(() => Text(
                controller.selectedLocation.value == null
                    ? 'Pilih Lokasi di Map'
                    : 'Ubah Lokasi',
              )),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ PAGE BARU: Notes & Photos
  Widget _buildNotesPhotosPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Tambahan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'Tambahkan catatan dan foto untuk membantu tim cleaning',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes & Photo Section
          const NotesPhotoSection(),
          
          const SizedBox(height: 16),
          
          // Optional Info
          Card(
            color: cs.surfaceVariant.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Informasi ini bersifat opsional namun sangat membantu tim untuk memberikan pelayanan terbaik',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
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

  Widget _buildDateTimePage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tanggal & Waktu Booking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Obx(() {
            final weather = controller.currentWeather.value;
            final bookingTime = controller.bookingData.value.bookingTime;
            final isInvalidTime = bookingTime != null && !controller.bookingData.value.isValidBookingTime();
            
            return Column(
              children: [
                Card(
                  color: cs.surface,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Pilih Tanggal'),
                    subtitle: Text(
                      controller.bookingData.value.bookingDate != null
                          ? '${controller.bookingData.value.bookingDate!.day}/${controller.bookingData.value.bookingDate!.month}/${controller.bookingData.value.bookingDate!.year}'
                          : 'Belum dipilih',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        controller.setBookingDate(date);
                        if (controller.selectedLocation.value != null) {
                          controller.loadWeatherForLocation(
                            controller.selectedLocation.value!.latitude,
                            controller.selectedLocation.value!.longitude,
                          );
                        }
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Card(
                  color: isInvalidTime ? cs.errorContainer : cs.surface,
                  child: ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: isInvalidTime ? cs.error : cs.onSurface,
                    ),
                    title: Text(
                      'Pilih Waktu (08:00 - 20:00)',
                      style: TextStyle(
                        color: isInvalidTime ? cs.error : cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      controller.bookingData.value.bookingTime != null
                          ? '${controller.bookingData.value.bookingTime!.hour.toString().padLeft(2, '0')}:${controller.bookingData.value.bookingTime!.minute.toString().padLeft(2, '0')}'
                          : 'Belum dipilih',
                      style: TextStyle(
                        color: isInvalidTime ? cs.error : cs.onSurface,
                        fontWeight: isInvalidTime ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        // Validate range before setting
                        final isValid = () {
                          final h = time.hour;
                          final m = time.minute;
                          if (h < 8) return false;
                          if (h > 20) return false;
                          if (h == 20 && m > 0) return false;
                          return true;
                        }();

                        if (!isValid) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking hanya tersedia jam 08:00 - 20:00'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          return;
                        }

                        controller.setBookingTime(time);
                      }
                    },
                    trailing: isInvalidTime
                        ? Icon(Icons.warning, color: cs.error)
                        : null,
                  ),
                ),
                
                if (isInvalidTime)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: cs.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Booking hanya tersedia jam 08:00 - 20:00.',
                              style: TextStyle(color: cs.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (weather != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Card(
                        color: cs.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cuaca Perkiraan',
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    weather.getWeatherIcon(),
                                    color: cs.onPrimaryContainer,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weather.getWeatherDescription(),
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${weather.temperature.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weather.getCleaningRecommendation(),
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'indoor':
        return Icons.home;
      case 'outdoor':
        return Icons.grass;
      case 'deep':
        return Icons.cleaning_services;
      case 'window':
        return Icons.window;
      default:
        return Icons.cleaning_services;
    }
  }
}