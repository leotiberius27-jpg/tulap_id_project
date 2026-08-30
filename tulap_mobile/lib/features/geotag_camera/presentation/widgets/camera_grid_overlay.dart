import 'package:flutter/material.dart';

/// CameraGridOverlay
/// ----------------------------------------------------------------------
/// Menampilkan overlay kisi 3x3 (Rule of Thirds) untuk membantu pengguna
/// menyelaraskan komposisi dokumentasi objek lapangan secara presisi:
/// - Garis putih tipis dengan opasitas rendah (anti-distraksi)
/// - Mengabaikan pointer gesture (IgnorePointer)
/// ----------------------------------------------------------------------
class CameraGridOverlay extends StatelessWidget {
  final bool visible;

  const CameraGridOverlay({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final oneThirdW = size.width / 3.0;
    final twoThirdW = (size.width * 2.0) / 3.0;

    final oneThirdH = size.height / 3.0;
    final twoThirdH = (size.height * 2.0) / 3.0;

    // Garis Vertikal
    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdW, 0), Offset(twoThirdW, size.height), paint);

    // Garis Horizontal
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdH), Offset(size.width, twoThirdH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
