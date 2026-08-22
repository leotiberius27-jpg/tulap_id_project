import 'package:flutter/material.dart';

/// TopographicBackground
/// ----------------------------------------------------------------------
/// Custom painter untuk menggambar kontur topografi halus khas Tulap.id
/// seperti pada referensi UI (kesan pemetaan & tugas lapangan).
/// ----------------------------------------------------------------------
class TopographicBackground extends StatelessWidget {
  final Widget child;
  final Color strokeColor;
  final double opacity;

  const TopographicBackground({
    super.key,
    required this.child,
    this.strokeColor = Colors.white,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopographicPainter(
        color: strokeColor.withValues(alpha: opacity),
      ),
      child: child,
    );
  }
}

class _TopographicPainter extends CustomPainter {
  final Color color;

  _TopographicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Garis kontur atas
    final path1 = Path()
      ..moveTo(-20, h * 0.05)
      ..cubicTo(w * 0.3, h * 0.02, w * 0.6, h * 0.09, w + 20, h * 0.04);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(-20, h * 0.12)
      ..cubicTo(w * 0.25, h * 0.07, w * 0.7, h * 0.16, w + 20, h * 0.09);
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(-20, h * 0.18)
      ..cubicTo(w * 0.4, h * 0.13, w * 0.8, h * 0.22, w + 20, h * 0.16);
    canvas.drawPath(path3, paint);

    // Garis kontur samping kiri
    final path4 = Path()
      ..moveTo(-10, h * 0.35)
      ..cubicTo(w * 0.2, h * 0.38, w * 0.25, h * 0.5, -10, h * 0.58);
    canvas.drawPath(path4, paint);

    final path5 = Path()
      ..moveTo(-10, h * 0.3)
      ..cubicTo(w * 0.28, h * 0.34, w * 0.32, h * 0.55, -10, h * 0.65);
    canvas.drawPath(path5, paint);

    // Garis kontur samping kanan
    final path6 = Path()
      ..moveTo(w + 10, h * 0.28)
      ..cubicTo(w * 0.75, h * 0.32, w * 0.7, h * 0.48, w + 10, h * 0.52);
    canvas.drawPath(path6, paint);

    final path7 = Path()
      ..moveTo(w + 10, h * 0.22)
      ..cubicTo(w * 0.68, h * 0.28, w * 0.62, h * 0.52, w + 10, h * 0.6);
    canvas.drawPath(path7, paint);

    // Garis kontur bawah
    final path8 = Path()
      ..moveTo(-20, h * 0.82)
      ..cubicTo(w * 0.35, h * 0.76, w * 0.65, h * 0.88, w + 20, h * 0.84);
    canvas.drawPath(path8, paint);

    final path9 = Path()
      ..moveTo(-20, h * 0.9)
      ..cubicTo(w * 0.3, h * 0.85, w * 0.7, h * 0.94, w + 20, h * 0.91);
    canvas.drawPath(path9, paint);
  }

  @override
  bool shouldRepaint(covariant _TopographicPainter oldDelegate) =>
      color != oldDelegate.color;
}
