import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// QrLocationGenerator
/// ----------------------------------------------------------------------
/// Menghasilkan URL dan bitmap QR Code lokasi Google Maps secara murni
/// on-device (offline) tanpa bergantung pada koneksi internet / API eksternal.
///
/// TUJUAN:
/// QR pada visual watermark berfungsi HANYA untuk "Buka Lokasi di Google Maps"
/// saat discan menggunakan perangkat kedua, dicetak di laporan PDF, atau fisik.
/// ----------------------------------------------------------------------
class QrLocationGenerator {
  /// Format URL query Google Maps standar yang kompatibel dengan browser & aplikasi Maps
  String buildGoogleMapsUrl({
    required double latitude,
    required double longitude,
  }) {
    final latStr = latitude.toStringAsFixed(6);
    final lngStr = longitude.toStringAsFixed(6);
    return 'https://www.google.com/maps/search/?api=1&query=$latStr,$lngStr';
  }

  /// Menghasilkan [ui.Image] QR code dengan latar belakang putih kontras tinggi,
  /// quiet zone aman, dan modul persegi presisi.
  Future<ui.Image> generateQrImage({
    required String data,
    required int pixelSize,
    ui.Color fgColor = const ui.Color(0xFF0F172A),
    ui.Color bgColor = const ui.Color(0xFFFFFFFF),
    int quietZoneModules = 2,
  }) async {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + (quietZoneModules * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final sizeDouble = pixelSize.toDouble();

    // 1. Gambar latar belakang putih (Quiet Zone)
    final bgRect = Rect.fromLTWH(0, 0, sizeDouble, sizeDouble);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(sizeDouble * 0.08)),
      bgPaint,
    );

    // 2. Hitung ukuran tiap modul
    final modulePixelSize = sizeDouble / totalModules;
    final fgPaint = Paint()..color = fgColor;

    // 3. Render modul QR
    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        if (qrImage.isDark(r, c)) {
          final left = (c + quietZoneModules) * modulePixelSize;
          final top = (r + quietZoneModules) * modulePixelSize;
          final moduleRect = Rect.fromLTWH(
            left,
            top,
            modulePixelSize + 0.5, // Sedikit overlap untuk mencegah celah rendering
            modulePixelSize + 0.5,
          );
          canvas.drawRect(moduleRect, fgPaint);
        }
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(pixelSize, pixelSize);
  }
}
