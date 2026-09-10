import 'package:flutter/material.dart';

/// buildFolderPath
/// ----------------------------------------------------------------------
/// Siluet folder sungguhan: tab (kiri-atas) -> shoulder (transisi
/// diagonal halus) -> body (badan folder) -> lip (tepi atas badan) ->
/// seluruh sudut membulat. Dipakai bersama oleh clipper (isi/gradient)
/// dan shadow painter (Bagian 3 dokumen redesign) supaya keduanya PASTI
/// identik pixel-demi-pixel.
/// ----------------------------------------------------------------------
Path buildFolderPath(
  Size size, {
  required double tabWidthFraction,
  required double tabHeight,
  required double cornerRadius,
}) {
  final w = size.width;
  final h = size.height;
  final tw = w * tabWidthFraction;
  final r = cornerRadius;
  final tabCorner = cornerRadius * 0.6;
  // Shoulder: transisi horizontal dari ujung kanan tab menuju tepi atas
  // badan folder - cukup lebar agar terlihat sebagai "bahu" yang landai,
  // bukan patahan tajam.
  final shoulderEnd = (tw + w * 0.10).clamp(tw + 12, w - r);

  final path = Path()
    ..moveTo(tabCorner, 0)
    ..lineTo(tw - tabCorner, 0)
    ..quadraticBezierTo(tw, 0, tw, tabCorner)
    ..lineTo(tw, tabHeight - tabCorner)
    ..quadraticBezierTo(tw, tabHeight, tw + tabCorner, tabHeight)
    ..lineTo(shoulderEnd - tabCorner, tabHeight)
    ..quadraticBezierTo(shoulderEnd, tabHeight, shoulderEnd, tabHeight)
    ..lineTo(w - r, tabHeight)
    ..quadraticBezierTo(w, tabHeight, w, tabHeight + r)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(r, h)
    ..quadraticBezierTo(0, h, 0, h - r)
    ..lineTo(0, tabCorner)
    ..quadraticBezierTo(0, 0, tabCorner, 0)
    ..close();

  return path;
}

/// FolderClipper
/// ----------------------------------------------------------------------
class FolderClipper extends CustomClipper<Path> {
  final double tabWidthFraction;
  final double tabHeight;
  final double cornerRadius;

  const FolderClipper({
    required this.tabWidthFraction,
    required this.tabHeight,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) => buildFolderPath(
    size,
    tabWidthFraction: tabWidthFraction,
    tabHeight: tabHeight,
    cornerRadius: cornerRadius,
  );

  @override
  bool shouldReclip(FolderClipper oldClipper) =>
      oldClipper.tabWidthFraction != tabWidthFraction ||
      oldClipper.tabHeight != tabHeight ||
      oldClipper.cornerRadius != cornerRadius;
}

/// FolderShadowPainter
/// ----------------------------------------------------------------------
/// Shadow yang MENGIKUTI siluet folder (bukan bayangan kotak generik) -
/// memakai `Canvas.drawShadow` (mekanisme native Skia, ringan) sesuai
/// prinsip performa Bagian 46 dokumen redesign.
/// ----------------------------------------------------------------------
class FolderShadowPainter extends CustomPainter {
  final double tabWidthFraction;
  final double tabHeight;
  final double cornerRadius;
  final double elevation;
  final Color shadowColor;

  const FolderShadowPainter({
    required this.tabWidthFraction,
    required this.tabHeight,
    required this.cornerRadius,
    required this.elevation,
    this.shadowColor = const Color(0xFF0F172A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation <= 0) return;
    final path = buildFolderPath(
      size,
      tabWidthFraction: tabWidthFraction,
      tabHeight: tabHeight,
      cornerRadius: cornerRadius,
    );
    canvas.drawShadow(path, shadowColor, elevation, false);
  }

  @override
  bool shouldRepaint(FolderShadowPainter oldDelegate) =>
      oldDelegate.elevation != elevation ||
      oldDelegate.tabWidthFraction != tabWidthFraction ||
      oldDelegate.tabHeight != tabHeight ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.shadowColor != shadowColor;
}
