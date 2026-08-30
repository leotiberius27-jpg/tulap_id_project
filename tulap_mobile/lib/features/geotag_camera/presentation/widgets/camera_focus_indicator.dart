import 'package:flutter/material.dart';

/// CameraFocusIndicator
/// ----------------------------------------------------------------------
/// Menampilkan indikator fokus interaktif berupa cincin dan tanda silang
/// halus saat user melakukan tap pada layar live camera preview:
/// - Muncul tepat pada koordinat tap user (local offset).
/// - Beranimasi mengecil (scale 1.35 -> 1.0) dengan aksen kuning terang.
/// - Menghilang secara otomatis (fade out) setelah ~650ms.
/// ----------------------------------------------------------------------
class CameraFocusIndicator extends StatelessWidget {
  final Offset position;
  final bool visible;

  const CameraFocusIndicator({
    super.key,
    required this.position,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    const size = 68.0;

    return Positioned(
      left: position.dx - (size / 2),
      top: position.dy - (size / 2),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.35, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: CustomPaint(
            size: const Size(size, size),
            painter: _FocusPainter(),
          ),
        ),
      ),
    );
  }
}

class _FocusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // 1. Cincin luar putih transparan untuk kontras latar belakang gelap/terang
    final outerRingPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(center, radius, outerRingPaint);

    // 2. Cincin utama warna Tulap.id Blue (#006EE6) & Sky Blue (#38BDF8)
    final ringPaint = Paint()
      ..color = const Color(0xFF006EE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, ringPaint);

    // 3. Tanda crosshair 4 sisi dengan aksen Cyan/Sky Blue cerah
    final crossPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const crossLen = 6.0;
    // Atas
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy - radius + crossLen),
      crossPaint,
    );
    // Bawah
    canvas.drawLine(
      Offset(center.dx, center.dy + radius),
      Offset(center.dx, center.dy + radius - crossLen),
      crossPaint,
    );
    // Kiri
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx - radius + crossLen, center.dy),
      crossPaint,
    );
    // Kanan
    canvas.drawLine(
      Offset(center.dx + radius, center.dy),
      Offset(center.dx + radius - crossLen, center.dy),
      crossPaint,
    );

    // 4. Titik pusat halus
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
