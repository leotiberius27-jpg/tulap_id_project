import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CameraZoomControls
/// ----------------------------------------------------------------------
/// Kontrol Quick Zoom profesional mengambang (Floating Quick Zoom Bubbles):
/// - Mendukung zoom dinamis (0.5x, 1x, 2x, 5x) sesuai kemampuan sensor lensa
/// - Indikator aktif berwarna Tulap.id Blue (#006EE6)
/// - Bubble non-aktif berdesain frosted dark glass dengan kontras tinggi
/// - Haptic feedback saat berpindah level pembesaran
/// ----------------------------------------------------------------------
class CameraZoomControls extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;

  const CameraZoomControls({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableLevels = _resolveZoomLevels();
    if (availableLevels.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableLevels.map((level) {
          final isSelected = (currentZoom - level).abs() < 0.25;

          return Semantics(
            button: true,
            label: 'Zoom ${level == 0.5 ? "0.5" : level.toInt()}x',
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onZoomChanged(level);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF006EE6) // Tulap.id Blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  level == 0.5
                      ? '0.5x'
                      : level == level.roundToDouble()
                          ? '${level.toInt()}x'
                          : '${level.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<double> _resolveZoomLevels() {
    final levels = <double>[];

    // Ultrawide (0.5x) jika didukung hardware
    if (minZoom <= 0.6) {
      levels.add(0.5);
    }

    // Standard 1x
    levels.add(1.0);

    // 2x Telephoto / Digital crop jika dalam range
    if (maxZoom >= 2.0) {
      levels.add(2.0);
    }

    // 5x High Zoom jika sensor mendukung
    if (maxZoom >= 5.0) {
      levels.add(5.0);
    }

    return levels;
  }
}
