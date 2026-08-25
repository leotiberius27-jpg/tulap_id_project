import 'package:flutter/material.dart';

/// GoogleLogoIcon
/// ----------------------------------------------------------------------
/// Ikon Google "G" 4 warna, digambar dari path resmi Google (viewBox
/// 18x18 yang dipakai tombol "Sign in with Google" resmi) via
/// CustomPainter murni - bebas dependency aset eksternal/paket SVG.
/// ----------------------------------------------------------------------
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 18, size.height / 18);

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    final bluePath = Path()
      ..moveTo(17.64, 9.2)
      ..cubicTo(17.64, 8.563, 17.583, 7.949, 17.476, 7.36)
      ..lineTo(9, 7.36)
      ..lineTo(9, 10.841)
      ..lineTo(13.844, 10.841)
      ..cubicTo(13.635, 11.966, 13.001, 12.919, 12.048, 13.558)
      ..lineTo(12.048, 15.816)
      ..lineTo(14.956, 15.816)
      ..cubicTo(16.658, 14.249, 17.64, 11.942, 17.64, 9.2)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    final greenPath = Path()
      ..moveTo(9, 18)
      ..cubicTo(11.43, 18, 13.467, 17.194, 14.956, 15.82)
      ..lineTo(12.048, 13.561)
      ..cubicTo(11.242, 14.101, 10.211, 14.421, 9, 14.421)
      ..cubicTo(6.656, 14.421, 4.672, 12.837, 3.964, 10.71)
      ..lineTo(0.957, 10.71)
      ..lineTo(0.957, 13.042)
      ..cubicTo(2.438, 15.983, 5.482, 18, 9, 18)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    final yellowPath = Path()
      ..moveTo(3.964, 10.71)
      ..cubicTo(3.784, 10.17, 3.682, 9.593, 3.682, 9.0)
      ..cubicTo(3.682, 8.407, 3.784, 7.83, 3.964, 7.29)
      ..lineTo(3.964, 4.958)
      ..lineTo(0.957, 4.958)
      ..cubicTo(0.347, 6.173, 0, 7.548, 0, 9)
      ..cubicTo(0, 10.452, 0.348, 11.827, 0.957, 13.042)
      ..lineTo(3.964, 10.71)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    final redPath = Path()
      ..moveTo(9, 3.58)
      ..cubicTo(10.321, 3.58, 11.508, 4.034, 12.44, 4.925)
      ..lineTo(15.022, 2.345)
      ..cubicTo(13.463, 0.891, 11.426, 0, 9, 0)
      ..cubicTo(5.482, 0, 2.438, 2.017, 0.957, 4.958)
      ..lineTo(3.964, 6.29)
      ..cubicTo(4.672, 4.163, 6.656, 2.58, 9, 2.58)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
