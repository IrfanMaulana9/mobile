import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/promotions.dart';
import '../models/promotion.dart';
import 'booking_page.dart';

class PromoPage extends StatefulWidget {
  static const String routeName = '/promo';
  
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  late List<Promotion> filteredPromos;
  String selectedFilter = 'all'; // all, active, upcoming

  @override
  void initState() {
    super.initState();
    _updateFilteredPromos();
  }

  void _updateFilteredPromos() {
    if (selectedFilter == 'active') {
      filteredPromos = promotions.where((p) => p.isActive).toList();
    } else if (selectedFilter == 'upcoming') {
      filteredPromos = promotions.where((p) => !p.isActive).toList();
    } else {
      filteredPromos = promotions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header dengan banner
          SliverAppBar(
            pinned: false,
            floating: true,
            expandedHeight: 180,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promo Spesial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dapatkan harga terbaik untuk layanan kebersihan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${filteredPromos.length} Promo Tersedia',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Semua',
                      'all',
                      cs,
                      selectedFilter == 'all',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Aktif Sekarang',
                      'active',
                      cs,
                      selectedFilter == 'active',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Akan Datang',
                      'upcoming',
                      cs,
                      selectedFilter == 'upcoming',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Promo list
          if (filteredPromos.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada promo',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final promo = filteredPromos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPromoCard(context, promo, cs),
                    );
                  },
                  childCount: filteredPromos.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    ColorScheme cs,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
          _updateFilteredPromos();
        });
      },
      backgroundColor: cs.surface,
      selectedColor: cs.primary.withValues(alpha: 0.2),
      side: BorderSide(
        color: isSelected ? cs.primary : cs.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    Promotion promo,
    ColorScheme cs,
  ) {
    return GestureDetector(
      onTap: () => Get.toNamed(BookingPage.routeName),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: cs.surface,
        ),
        child: Column(
          children: [
            // Header dengan badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: promo.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: promo.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      promo.icon,
                      color: promo.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.serviceName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          promo.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(promo),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      promo.badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten utama
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Harga
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Normal',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Rp${promo.originalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 40,
                          width: 2,
                          color: cs.outlineVariant,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Harga Promo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-${promo.discountPercentage}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Rp${promo.promoPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Syarat dan ketentuan
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syarat & Ketentuan:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...promo.terms.map((term) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  term,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time remaining & button
                  Row(
                    children: [
                      if (promo.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${promo.daysRemaining} hari lagi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => Get.toNamed(BookingPage.routeName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_cart, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Pesan Sekarang',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(Promotion promo) {
    if (promo.badge == 'Flash Sale') {
      return Colors.red;
    } else if (promo.badge == 'Limited Time') {
      return Colors.orange;
    } else if (promo.badge == 'Hot Deal') {
      return Colors.deepOrange;
    } else {
      return Colors.teal;
    }
  }
}
