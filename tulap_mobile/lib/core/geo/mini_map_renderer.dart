import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// MiniMapRenderer
/// ----------------------------------------------------------------------
/// Merender panel mini-map visual kontekstual untuk watermark bukti geotag.
///
/// PERILAKU OFFLINE & NON-BLOCKING:
/// - Jika gambar peta statis (OSM/Google Maps tile) tersedia -> dirender dengan rapi.
/// - Jika offline / gagal dimuat -> otomatis membuat representasi grafis
///   prosedural (vektor grid koordinat, radar target, dan pin lokasi Tulap.id)
///   sehingga proses shutter dan penyimpanan bukti TIDAK PERNAH terhenti.
/// ----------------------------------------------------------------------
class MiniMapRenderer {
  /// Merender [ui.Image] mini-map persegi dengan ukuran [pixelSize] x [pixelSize].
  Future<ui.Image> renderMiniMap({
    required double latitude,
    required double longitude,
    required int pixelSize,
    Uint8List? staticMapBytes,
  }) async {
    if (staticMapBytes != null && staticMapBytes.isNotEmpty) {
      try {
        final codec = await ui.instantiateImageCodec(staticMapBytes);
        final frame = await codec.getNextFrame();
        final sourceMap = frame.image;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final sizeDouble = pixelSize.toDouble();
        final rect = Rect.fromLTWH(0, 0, sizeDouble, sizeDouble);
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(sizeDouble * 0.12),
        );

        canvas.clipRRect(rrect);

        // Gambar tile peta
        final srcRect = Rect.fromLTWH(
          0,
          0,
          sourceMap.width.toDouble(),
          sourceMap.height.toDouble(),
        );
        canvas.drawImageRect(sourceMap, srcRect, rect, Paint());

        // Border halus
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = const ui.Color(0x66FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        final picture = recorder.endRecording();
        return picture.toImage(pixelSize, pixelSize);
      } catch (_) {
        // Fallback ke grafis prosedural jika decoding gagal
      }
    }

    return _generateProceduralMap(
      latitude: latitude,
      longitude: longitude,
      pixelSize: pixelSize,
    );
  }

  /// Menghasilkan panel mini map prosedural yang bersih saat offline
  Future<ui.Image> _generateProceduralMap({
    required double latitude,
    required double longitude,
    required int pixelSize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = pixelSize.toDouble();
    final rect = Rect.fromLTWH(0, 0, size, size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size * 0.12),
    );

    canvas.clipRRect(rrect);

    // 1. Background Peta Lapangan Gelap (Netral Charcoal - BUKAN Biru)
    // Sebelumnya gradient ini biru-navy (0xFF0F172A -> 0xFF1E293B) DAN
    // grid/radar/border di atasnya juga biru (0x38BDF8/0x006EE6),
    // sehingga panel mini-map tampak sebagai kotak biru mencolok di
    // pojok foto bukti - dilaporkan langsung oleh pengguna sebagai
    // mengganggu setelah melihat hasil foto asli. Diganti netral abu-abu
    // gelap agar menyatu dengan panel stamp lain (yang sudah hitam/navy
    // gelap ~85% opacity), TANPA menghilangkan info peta (grid, radar,
    // pin, koordinat) itu sendiri.
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size, size),
        [
          const ui.Color(0xFF14171C),
          const ui.Color(0xFF23262D),
        ],
      );
    canvas.drawRect(rect, bgPaint);

    // 2. Garis Grid Koordinat & Jalan Prosedural
    final gridPaint = Paint()
      ..color = const ui.Color(0x22FFFFFF)
      ..strokeWidth = (size * 0.015).clamp(1.0, 3.0);

    final step = size / 5;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(step * i, 0), Offset(step * i, size), gridPaint);
      canvas.drawLine(Offset(0, step * i), Offset(size, step * i), gridPaint);
    }

    // Jalan diagonal / kontur kontekstual
    final roadPaint = Paint()
      ..color = const ui.Color(0x3364748B)
      ..strokeWidth = size * 0.06;
    final roadPath = Path()
      ..moveTo(0, size * 0.7)
      ..cubicTo(size * 0.3, size * 0.65, size * 0.6, size * 0.4, size, size * 0.25);
    canvas.drawPath(roadPath, roadPaint);

    // 3. Radar Lingkaran Target Akurasi
    final center = Offset(size / 2, size / 2);
    final radarPaint = Paint()
      ..color = const ui.Color(0x26FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.32, radarPaint);

    final radarBorder = Paint()
      ..color = const ui.Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, size * 0.32, radarBorder);
    canvas.drawCircle(center, size * 0.18, radarBorder);

    // 4. Pin Lokasi Tulap.id (Merah / Biru tegas)
    final pinPaint = Paint()..color = const ui.Color(0xFFEF4444);
    final pinShadow = Paint()
      ..color = const ui.Color(0x80000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    
    canvas.drawCircle(center.translate(0, size * 0.08), size * 0.08, pinShadow);

    final pinPath = Path()
      ..moveTo(center.dx, center.dy + size * 0.1)
      ..lineTo(center.dx - size * 0.09, center.dy - size * 0.04)
      ..arcTo(
        Rect.fromCircle(center: center.translate(0, -size * 0.04), radius: size * 0.09),
        math.pi * 0.8,
        math.pi * 1.4,
        false,
      )
      ..close();
    canvas.drawPath(pinPath, pinPaint);

    // Titik pusat pin
    canvas.drawCircle(
      center.translate(0, -size * 0.04),
      size * 0.035,
      Paint()..color = Colors.white,
    );

    // 5. Chip Koordinat Ringkas di Bagian Bawah
    final latLngStr =
        '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
    final coordPainter = TextPainter(
      text: TextSpan(
        text: latLngStr,
        style: TextStyle(
          color: const ui.Color(0xFFE2E8F0),
          fontSize: (size * 0.09).clamp(8.0, 16.0),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size - 8);

    final chipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size / 2, size - (coordPainter.height * 0.9)),
        width: coordPainter.width + (size * 0.1),
        height: coordPainter.height + 4,
      ),
      Radius.circular(size * 0.05),
    );
    canvas.drawRRect(
      chipRect,
      Paint()..color = const ui.Color(0xCC0B1220),
    );
    coordPainter.paint(
      canvas,
      Offset(
        (size - coordPainter.width) / 2,
        size - (coordPainter.height * 1.4),
      ),
    );

    // 6. Border Luar
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const ui.Color(0x40FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final picture = recorder.endRecording();
    return picture.toImage(pixelSize, pixelSize);
  }
}
