import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CameraLevelOverlay
/// ----------------------------------------------------------------------
/// Indikator waterpass / horizon level kamera (Phase 4):
/// - Menampilkan garis horizon dan bubble indikator di tengah layar
/// - Sudut dihitung dari sensor accelerometer (roll angle)
/// - Berubah menjadi Tulap Success Green saat posisi sejajar (|roll| <= 1.5°)
/// - Hanya overlay preview, TIDAK PERNAH tercetak ke dalam foto/video bukti
/// ----------------------------------------------------------------------
class CameraLevelOverlay extends StatelessWidget {
  final double rollDegrees;
  final bool isLevel;
  final bool visible;

  const CameraLevelOverlay({
    super.key,
    required this.rollDegrees,
    required this.isLevel,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final successGreen = const Color(0xFF22C55E);
    final indicatorColor = isLevel ? successGreen : Colors.white70;

    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garis Horizon Berotasi
            Transform.rotate(
              angle: -rollDegrees * (math.pi / 180.0),
              child: SizedBox(
                width: 220,
                height: 24,
                child: CustomPaint(
                  painter: _LevelPainter(
                    isLevel: isLevel,
                    rollDegrees: rollDegrees,
                    indicatorColor: indicatorColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Badge Nilai Sudut Derajat
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLevel
                    ? successGreen.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLevel ? successGreen : Colors.white24,
                  width: 1,
                ),
              ),
              child: Text(
                isLevel ? 'SEJAJAR (0°)' : '${rollDegrees.toStringAsFixed(1)}°',
                style: TextStyle(
                  color: isLevel ? successGreen : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPainter extends CustomPainter {
  final bool isLevel;
  final double rollDegrees;
  final Color indicatorColor;

  _LevelPainter({
    required this.isLevel,
    required this.rollDegrees,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = indicatorColor
      ..strokeWidth = isLevel ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    // Garis kiri
    canvas.drawLine(
      Offset(0, centerY),
      Offset(centerX - 24, centerY),
      linePaint,
    );

    // Garis kanan
    canvas.drawLine(
      Offset(centerX + 24, centerY),
      Offset(size.width, centerY),
      linePaint,
    );

    // Lingkaran tengah (Level Target Bubble)
    final circlePaint = Paint()
      ..color = indicatorColor
      ..style = isLevel ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(centerX, centerY), 6, circlePaint);

    if (isLevel) {
      final glowPaint = Paint()
        ..color = const Color(0x6622C55E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(centerX, centerY), 10, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPainter oldDelegate) {
    return oldDelegate.rollDegrees != rollDegrees ||
        oldDelegate.isLevel != isLevel;
  }
}
