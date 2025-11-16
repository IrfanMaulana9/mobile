import 'package:flutter/material.dart';

class AnimationControllerDemoPage extends StatefulWidget {
  static const routeName = '/animationcontroller-demo';
  const AnimationControllerDemoPage({super.key});

  @override
  State<AnimationControllerDemoPage> createState() => _AnimationControllerDemoPageState();
}

class _AnimationControllerDemoPageState extends State<AnimationControllerDemoPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  double _durationMs = 1200;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs.round()),
    );

    // Kombinasi Tween untuk demonstrasi
    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotation = Tween<double>(begin: 0.0, end: 2 * 3.1415926).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restartWithDuration() {
    final isAnimating = _controller.isAnimating;
    _controller.dispose();
    _initController();
    if (isAnimating) {
      _controller.repeat(); // lanjut repeat bila sebelumnya repeat
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimationController (Eksplisit)'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kontrol
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(onPressed: () => _controller.forward(), child: const Text('Mulai')),    // Start -> Mulai
                FilledButton(onPressed: () => _controller.stop(), child: const Text('Hentikan')),    // Stop -> Hentikan
                FilledButton(onPressed: () => _controller.repeat(), child: const Text('Ulangi')),    // Repeat -> Ulangi
                FilledButton(onPressed: () => _controller.reverse(), child: const Text('Balik')),    // Reverse -> Balik
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Hero(
                  tag: AnimationControllerDemoPage.routeName,
                  child: CircleAvatar(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    child: const Icon(Icons.tune),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Kontrol durasi, curve, arah animasi', style: TextStyle(color: cs.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Durasi: ${_durationMs.round()} ms'),
                Expanded(
                  child: Slider(
                    value: _durationMs,
                    min: 300,
                    max: 3000,
                    divisions: 27,
                    label: '${_durationMs.round()} ms',
                    onChanged: (v) => setState(() => _durationMs = v),
                    onChangeEnd: (_) => _restartWithDuration(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _rotation.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade600,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Clean',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Text(
              'Gunakan Flutter DevTools → Performance untuk memprofil CPU/GPU saat animasi berjalan.', // Perjelas kalimat Indonesia
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
