import 'package:flutter/material.dart';

/// GoogleLogoIcon
/// ----------------------------------------------------------------------
/// Menghasilkan ikon Google "G" 4 warna autentik menggunakan CustomPainter
/// murni (bebas dependency aset eksternal dan resolusi tajam).
/// ----------------------------------------------------------------------
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Paint objek
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;

    // Lingkaran luar clip
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue arc & bar
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -0.4, 1.2, false)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green arc
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0.8, 1.5, false)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow arc
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 2.3, 1.2, false)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red arc
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 3.5, 1.3, false)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Lubang tengah (putih)
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.58, whitePaint);

    // Bar horizontal biru di tengah
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - radius * 0.05, center.dy - radius * 0.22, radius * 1.05, radius * 0.44),
      Radius.circular(radius * 0.08),
    );
    canvas.drawRRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
