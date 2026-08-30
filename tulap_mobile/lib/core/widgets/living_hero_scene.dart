import 'dart:math' as math;
import 'package:flutter/material.dart';

/// LivingHeroScene
/// ----------------------------------------------------------------------
/// Menampilkan ilustrasi Beranda Tulap.id dengan animasi kedipan mata
/// kedua karakter yang hidup, natural, dan presisi 1:1:
/// - Mata berkedip secara organik setiap ~3.2 detik (durasi kedipan 140ms).
/// - Saat mata terbuka normal, 100% menggunakan gambar asli tanpa interferensi.
/// - Saat berkedip, kelopak mata menutup mulus dengan warna kulit asli dan
///   lengkungan bulu mata tersenyum yang rapi dan serasi dengan gaya ilustrasi.
/// - Bebas terpotong (no clipping).
/// ----------------------------------------------------------------------
class LivingHeroScene extends StatefulWidget {
  final double height;

  const LivingHeroScene({super.key, this.height = 360});

  @override
  State<LivingHeroScene> createState() => _LivingHeroSceneState();
}

class _LivingHeroSceneState extends State<LivingHeroScene>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _blinkController;

  static const Size _imageIntrinsicSize = Size(812, 700);

  @override
  void initState() {
    super.initState();

    // 1. Pernapasan / gerakan mengambang sangat lembut
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    // 2. Controller siklus kedipan mata (berjalan setiap 3.4 detik)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_breatheController, _blinkController]),
            builder: (context, _) {
              final breatheY =
                  math.sin(_breatheController.value * math.pi) * 2.2;
              final blinkAmount = _calculateBlinkAmount(_blinkController.value);

              return Transform.translate(
                offset: Offset(0, breatheY),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final containerSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    final fittedSizes = applyBoxFit(
                      BoxFit.contain,
                      _imageIntrinsicSize,
                      containerSize,
                    );
                    final imageDestRect = Alignment.bottomCenter.inscribe(
                      fittedSizes.destination,
                      Rect.fromLTWH(
                        0,
                        0,
                        containerSize.width,
                        containerSize.height,
                      ),
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Layer 1: Gambar Ilustrasi Asli
                        Positioned.fromRect(
                          rect: imageDestRect,
                          child: Image.asset(
                            'assets/images/hero_illustration.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),

                        // Layer 2: Animasi Kedipan Mata Alami untuk Kedua Karakter
                        if (blinkAmount > 0.01)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _NaturalBlinkPainter(
                                destRect: imageDestRect,
                                blinkProgress: blinkAmount,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Menghitung kurva kedipan mata natural (durasi kedipan 140ms per 3.4 detik)
  double _calculateBlinkAmount(double cycle) {
    // 0.00 - 0.94: Mata terbuka normal (0.0)
    // 0.94 - 0.97: Kelopak mata menutup cepat (0.0 -> 1.0)
    // 0.97 - 0.98: Tertutup rapat (1.0)
    // 0.98 - 1.00: Kelopak mata membuka kembali (1.0 -> 0.0)
    if (cycle < 0.94) return 0.0;
    if (cycle >= 0.94 && cycle < 0.97) {
      return (cycle - 0.94) / 0.03; // 0.0 -> 1.0
    }
    if (cycle >= 0.97 && cycle < 0.98) {
      return 1.0;
    }
    if (cycle >= 0.98 && cycle <= 1.00) {
      return 1.0 - ((cycle - 0.98) / 0.02); // 1.0 -> 0.0
    }
    return 0.0;
  }
}

/// _NaturalBlinkPainter
/// ----------------------------------------------------------------------
/// Menggambar kelopak mata berkedip secara natural pada kedua karakter:
/// - Karakter Kiri (Pegang HP):
///   * Mata Kiri: (0.3103, 0.4443)
///   * Mata Kanan: (0.3658, 0.4471)
/// - Karakter Kanan (Bawa Clipboard):
///   * Mata Kiri: (0.5837, 0.4514)
///   * Mata Kanan: (0.6490, 0.4557)
/// ----------------------------------------------------------------------
class _NaturalBlinkPainter extends CustomPainter {
  final Rect destRect;
  final double blinkProgress;

  _NaturalBlinkPainter({required this.destRect, required this.blinkProgress});

  Offset _toScreen(double nx, double ny) {
    return Offset(
      destRect.left + nx * destRect.width,
      destRect.top + ny * destRect.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (blinkProgress <= 0.01) return;

    final dw = destRect.width;
    final dh = destRect.height;

    // --- Karakter Kiri (Petugas Pegang HP) ---
    // Mata Kiri
    _drawSmilingEyeBlink(
      canvas: canvas,
      center: _toScreen(0.3103, 0.4443),
      width: dw * 0.021,
      height: dh * 0.014,
      progress: blinkProgress,
      tiltRad: 0.08,
    );

    // Mata Kanan
    _drawSmilingEyeBlink(
      canvas: canvas,
      center: _toScreen(0.3658, 0.4471),
      width: dw * 0.021,
      height: dh * 0.014,
      progress: blinkProgress,
      tiltRad: 0.06,
    );

    // --- Karakter Kanan (Petugas Bawa Clipboard) ---
    // Mata Kiri
    _drawSmilingEyeBlink(
      canvas: canvas,
      center: _toScreen(0.5837, 0.4514),
      width: dw * 0.020,
      height: dh * 0.0135,
      progress: blinkProgress,
      tiltRad: -0.04,
    );

    // Mata Kanan
    _drawSmilingEyeBlink(
      canvas: canvas,
      center: _toScreen(0.6490, 0.4557),
      width: dw * 0.020,
      height: dh * 0.0135,
      progress: blinkProgress,
      tiltRad: 0.03,
    );
  }

  void _drawSmilingEyeBlink({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required double progress,
    required double tiltRad,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (tiltRad != 0) canvas.rotate(tiltRad);

    final hw = width / 2;
    final currentH = height * progress;

    // 1. Warna kulit kelopak mata asli ilustrasi
    final skinPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3AB82), Color(0xFFE89B6D), Color(0xFFDC8C5C)],
      ).createShader(Rect.fromLTWH(-hw, -height * 0.6, width, height * 1.3));

    // Menutup pupil dengan kelopak mata
    final lidRect = Rect.fromCenter(
      center: Offset(0, currentH * 0.1),
      width: width * 1.12,
      height: currentH * 1.9,
    );
    canvas.clipRRect(RRect.fromRectAndRadius(lidRect, Radius.circular(hw)));
    canvas.drawRect(lidRect, skinPaint);

    // 2. Garis bulu mata tersenyum (curved lash arc)
    final lashPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round;

    final lashPath = Path()
      ..moveTo(-hw * 0.95, currentH * 0.2)
      ..quadraticBezierTo(0, currentH * 0.85, hw * 0.95, currentH * 0.2);
    canvas.drawPath(lashPath, lashPaint);

    // 3. Lipatan kelopak mata atas halus saat tertutup
    if (progress > 0.6) {
      final creasePaint = Paint()
        ..color = const Color(0xFFD67F4F).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..strokeCap = StrokeCap.round;

      final creasePath = Path()
        ..moveTo(-hw * 0.75, -currentH * 0.4)
        ..quadraticBezierTo(0, -currentH * 0.75, hw * 0.75, -currentH * 0.4);
      canvas.drawPath(creasePath, creasePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NaturalBlinkPainter oldDelegate) {
    return oldDelegate.destRect != destRect ||
        oldDelegate.blinkProgress != blinkProgress;
  }
}
