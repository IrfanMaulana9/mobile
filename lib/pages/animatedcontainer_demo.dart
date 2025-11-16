import 'package:flutter/material.dart';

class AnimatedContainerDemoPage extends StatefulWidget {
  static const routeName = '/animatedcontainer-demo';
  const AnimatedContainerDemoPage({super.key});

  @override
  State<AnimatedContainerDemoPage> createState() => _AnimatedContainerDemoPageState();
}

class _AnimatedContainerDemoPageState extends State<AnimatedContainerDemoPage> {
  static const int itemCount = 8;
  final List<bool> _active = List<bool>.filled(itemCount, false);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimatedContainer (Implisit)'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Hero(
                  tag: AnimatedContainerDemoPage.routeName,
                  child: CircleAvatar(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    child: const Icon(Icons.animation),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Efek transisi halus antar nilai properti', style: TextStyle(color: cs.onSurface)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // fokus demo implisit
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final isOn = _active[index];
                return InkWell(
                  onTap: () => setState(() => _active[index] = !isOn),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: isOn ? 140 : 110,
                      height: isOn ? 140 : 110,
                      decoration: BoxDecoration(
                        color: isOn ? Colors.amber : Colors.teal,
                        borderRadius: BorderRadius.circular(isOn ? 28 : 12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: isOn ? 14 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isOn ? 'Aktif' : 'Nonaktif',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
