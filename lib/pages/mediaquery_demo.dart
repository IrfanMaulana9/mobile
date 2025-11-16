import 'package:flutter/material.dart';
import '../widgets/service_card.dart';

class MediaQueryDemoPage extends StatefulWidget {
  static const routeName = '/mediaquery-demo';
  const MediaQueryDemoPage({super.key});

  @override
  State<MediaQueryDemoPage> createState() => _MediaQueryDemoPageState();
}

class _MediaQueryDemoPageState extends State<MediaQueryDemoPage> with TickerProviderStateMixin {
  double _spacing = 12;
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  int _durMs = 1200;

  final Set<int> _aktif = {}; // indeks item aktif (akan pulse)

  int _columnsForWidth(double w) {
    if (w < 600) return 2;
    if (w < 900) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: _durMs));
    _pulse = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cols = _columnsForWidth(size.width);
    final cs = Theme.of(context).colorScheme;

    final services = [
      (Icons.cleaning_services, 'Pel Lantai'),
      (Icons.local_laundry_service, 'Laundry'),
      (Icons.layers, 'Cuci Karpet'),
      (Icons.kitchen, 'Kebersihan Dapur'),
      (Icons.sanitizer, 'Disinfeksi'),
      (Icons.window, 'Cuci Kaca'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaQuery: Grid Responsif'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: MediaQueryDemoPage.routeName,
                  child: CircleAvatar(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    child: const Icon(Icons.grid_view),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lebar layar: ${size.width.toStringAsFixed(0)} px • Kolom: $cols'),
                      const SizedBox(height: 8),
                      Text('Jarak Grid: ${_spacing.toStringAsFixed(0)}'),
                      Slider(
                        value: _spacing,
                        min: 0,
                        max: 32,
                        divisions: 32,
                        onChanged: (v) => setState(() => _spacing = v),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => _ctrl.forward(),
                            child: const Text('Mulai'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _ctrl.repeat(reverse: true),
                            child: const Text('Ulangi'),
                          ),
                          OutlinedButton(
                            onPressed: () => _ctrl.stop(),
                            child: const Text('Hentikan'),
                          ),
                          OutlinedButton(
                            onPressed: () => _ctrl.reset(),
                            child: const Text('Reset'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Durasi:'),
                              const SizedBox(width: 8),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return GridView.builder(
                  padding: EdgeInsets.all(_spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: _spacing,
                    mainAxisSpacing: _spacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: services.length,
                  itemBuilder: (_, i) {
                    final (icon, title) = services[i];
                    final aktif = _aktif.contains(i);
                    final bgColor = aktif ? cs.primaryContainer : Colors.green; // default putih, saat aktif gunakan warna hijau container
                    final scale = aktif ? _pulse.value : 1.0;
                    return ServiceCard(
                      icon: icon,
                      title: title,
                      color: bgColor,
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
                            if (!_ctrl.isAnimating) {
                              _ctrl.repeat(reverse: true);
                            }
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
            ),
          ),
        ],
      ),
    );
  }
}
