import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double scale;
  final bool aktif; // apakah sedang ditoggle (untuk animasi implisit)
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.scale = 1.0,
    this.aktif = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color onBg(Color bg) => bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: aktif ? color.withOpacity(0.9) : color,
            borderRadius: BorderRadius.circular(aktif ? 18 : 12),
            border: Border.all(color: cs.onSurface.withOpacity(0.06), width: 1),
            boxShadow: aktif
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          padding: EdgeInsets.all(aktif ? 16 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: onBg(aktif ? color.withOpacity(0.9) : color)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: onBg(aktif ? color.withOpacity(0.9) : color), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
