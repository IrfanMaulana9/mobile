import 'package:flutter/material.dart';

class LocationModeSelector extends StatefulWidget {
  final String selectedMode;
  final Function(String mode) onModeChanged;

  const LocationModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  State<LocationModeSelector> createState() => _LocationModeSelectorState();
}

class _LocationModeSelectorState extends State<LocationModeSelector> {
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.selectedMode;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode Lokasi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  context,
                  'gps',
                  'GPS',
                  Icons.satellite_alt,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeButton(
                  context,
                  'network',
                  'Jaringan',
                  Icons.cloud,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeButton(
                  context,
                  'hybrid',
                  'Hibrida',
                  Icons.sync_alt,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String mode,
    String label,
    IconData icon,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = mode);
        widget.onModeChanged(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : cs.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
