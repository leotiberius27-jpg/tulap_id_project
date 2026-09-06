import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CameraZoomControls
/// ----------------------------------------------------------------------
/// Kontrol Quick Zoom profesional mengambang (Floating Quick Zoom Bubbles)
/// Sesuai referensi 01.jpeg:
/// - Indikator aktif lingkaran kuning cerah (#FFC700) dengan teks hitam pekat
/// - Indikator non-aktif teks putih bersih dengan kontras tinggi
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 10 : 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFC700) // Golden Yellow from 01.jpeg
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
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 12.0,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.2,
                    shadows: isSelected
                        ? null
                        : const [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
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

