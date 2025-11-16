import 'package:flutter/material.dart';
import 'dart:math' as math;

class LayoutBuilderDemoPage extends StatelessWidget {
  static const routeName = '/layoutbuilder-demo';
  const LayoutBuilderDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LayoutBuilder: Layanan Adaptif'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: const _AdaptiveGrid(),
    );
  }
}

class _AdaptiveGrid extends StatefulWidget {
  const _AdaptiveGrid();

  @override
  State<_AdaptiveGrid> createState() => _AdaptiveGridState();
}

class _AdaptiveGridState extends State<_AdaptiveGrid> with TickerProviderStateMixin {
  static const List<(IconData, String, Color)> _layanan = [
    (Icons.cleaning_services, 'Pel Lantai', Color(0xFF66BB6A)),   // hijau 400
    (Icons.local_laundry_service, 'Laundry', Color(0xFF26A69A)),  // teal 400
    (Icons.layers, 'Cuci Karpet', Color(0xFFAED581)),             // lightGreen 300
    (Icons.kitchen, 'Kebersihan Dapur', Color(0xFF9CCC65)),       // lightGreen 400
    (Icons.sanitizer, 'Disinfeksi', Color(0xFF26C6DA)),           // cyan 400
    (Icons.window, 'Cuci Kaca', Color(0xFF80CBC4)),               // teal 200
  ];

  final Set<int> _aktif = {};
  late final AnimationController _ctrl;
  late Animation<double> _pulse;
  int _durMs = 1200;
  double _spacing = 16;

  int _cols(double w) {
    if (w < 360) return 1;
    if (w < 640) return 2;  // ponsel
    if (w < 920) return 3;  // tablet kecil
    return 4;               // layar besar
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: _durMs));
    _pulse = Tween(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: LayoutBuilderDemoPage.routeName,
                    child: CircleAvatar(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      child: const Icon(Icons.grid_view),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Grid adaptif berdasarkan ruang lokal (LayoutBuilder)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Jarak'),
                  Expanded(
                    child: Slider(
                      value: _spacing,
                      min: 8,
                      max: 32,
                      divisions: 24,
                      label: '${_spacing.round()}',
                      onChanged: (v) => setState(() => _spacing = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Durasi'),
                  SizedBox(
                    width: 160,
                    child: Slider(
                      value: _durMs.toDouble(),
                      min: 400,
                      max: 2400,
                      divisions: 20,
                      label: '${_durMs}ms',
                      onChanged: (v) {
                        setState(() {
                          _durMs = v.round();
                          _ctrl.duration = Duration(milliseconds: _durMs);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () => _ctrl.forward(), child: const Text('Mulai')),
                  FilledButton.tonal(onPressed: () => _ctrl.repeat(reverse: true), child: const Text('Ulangi')),
                  OutlinedButton(onPressed: () => _ctrl.stop(), child: const Text('Hentikan')),
                  OutlinedButton(onPressed: () => _ctrl.reset(), child: const Text('Reset')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final cols = _cols(c.maxWidth);
              final effectiveSpacing = math.max(_spacing, isPortrait ? 16.0 : 10.0);

              return AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return GridView.builder(
                    padding: EdgeInsets.all(effectiveSpacing),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: effectiveSpacing,
                      mainAxisSpacing: effectiveSpacing,
                      childAspectRatio: 1,
                    ),
                    itemCount: _layanan.length,
                    itemBuilder: (_, i) {
                      final (icon, title, baseColor) = _layanan[i];
                      final aktif = _aktif.contains(i);
                      final bg = aktif ? Color.alphaBlend(Colors.black12, baseColor) : baseColor;
                      final scale = aktif ? _pulse.value : 1.0;

                      return _ServiceTile(
                        icon: icon,
                        title: title,
                        color: bg,
                        scale: scale,
                        aktif: aktif,
                        onTap: () {
                          setState(() {
                            if (aktif) {
                              _aktif.remove(i);
                            } else {
                              _aktif.add(i);
                            }
                            if (_aktif.isNotEmpty) {
                              if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
                            } else {
                              _ctrl.stop();
                              _ctrl.reset();
                            }
                          });
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double scale;
  final bool aktif;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.scale,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;

    // dan warna ikon/teks menyesuaikan kontras (hitam/putih). Saat normal, putih (surface).
    final bg = color;
    final containerColor = aktif ? bg : surface;
    final isBgLight = bg.computeLuminance() > 0.5;
    final foregroundOnBg = isBgLight ? Colors.black : Colors.white;
    final titleColor = aktif ? foregroundOnBg : cs.onSurface;
    final iconColor = aktif ? foregroundOnBg : bg;
    final borderWidth = aktif ? 0.0 : 2.0;
    final shadowColor = aktif ? bg.withOpacity(0.4) : bg.withOpacity(0.25);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: containerColor, // isi latar belakang berubah saat aktif
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bg, width: borderWidth), // border disembunyikan saat aktif
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32, color: iconColor),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
