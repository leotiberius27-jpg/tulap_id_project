import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// WatermarkData
/// ----------------------------------------------------------------------
/// Semua nilai yang perlu ditulis ke watermark permanen di foto bukti.
/// Dikumpulkan lebih dulu oleh caller (controller/datasource) agar
/// WatermarkCompositor sendiri murni fungsi rendering - tidak perlu tahu
/// dari mana data ini berasal (GPS, reverse-geocoding, dst).
/// ----------------------------------------------------------------------
class WatermarkData {
  final String officerName;
  final String? nip;
  final String agencyName;
  final String taskId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String plusCode;
  final String? address;
  final String auditQrPayload;

  /// Bytes PNG/JPEG thumbnail peta statis - `null` kalau tidak berhasil
  /// diambil (mis. tidak ada koneksi saat itu). Watermark tetap
  /// dihasilkan tanpa thumbnail peta kalau ini null, sesuai prinsip
  /// offline-first aplikasi - proses capture TIDAK boleh gagal hanya
  /// karena thumbnail peta gagal diunduh.
  final Uint8List? staticMapImageBytes;

  const WatermarkData({
    required this.officerName,
    this.nip,
    required this.agencyName,
    required this.taskId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.plusCode,
    this.address,
    required this.auditQrPayload,
    this.staticMapImageBytes,
  });
}

/// WatermarkCompositor
/// ----------------------------------------------------------------------
/// Menggambar (bukan sekadar overlay UI - lihat catatan lama di
/// WatermarkOverlay) watermark PERMANEN ke byte gambar asli, memakai
/// `dart:ui` Canvas murni (tanpa dependency image-processing tambahan).
/// Output selalu PNG (satu-satunya format ekspor native `dart:ui`) -
/// caller (GeotagCameraLocalDataSource) yang lalu mengonversinya ke JPEG
/// terkompresi lewat langkah kompresi yang sudah ada.
/// ----------------------------------------------------------------------
class WatermarkCompositor {
  static const _panelColor = ui.Color(0x8C000000); // black @ ~55% alpha
  static const _accentColor = ui.Color(0xFF00529C); // AppColors.primary
  static const _textColor = ui.Color(0xFFFFFFFF);

  Future<Uint8List> compose({
    required Uint8List sourceImageBytes,
    required WatermarkData data,
  }) async {
    final sourceImage = await _decodeImage(sourceImageBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Gambar foto asli apa adanya sebagai lapisan dasar.
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    final width = sourceImage.width.toDouble();
    final height = sourceImage.height.toDouble();

    // 2. Susun panel watermark di bagian bawah, tinggi proporsional
    // terhadap lebar foto agar konsisten di berbagai resolusi kamera.
    final panelPadding = width * 0.03;
    final qrSize = width * 0.16;
    final mapSize = data.staticMapImageBytes != null ? width * 0.16 : 0.0;
    final rightColumnWidth = qrSize + (mapSize > 0 ? mapSize + panelPadding : 0);
    final textColumnWidth = width - (panelPadding * 3) - rightColumnWidth;

    final lines = _buildTextLines(data);
    final fontSize = width * 0.017;
    final painters = lines
        .map((l) => _buildTextPainter(l, fontSize, textColumnWidth))
        .toList();
    final textBlockHeight =
        painters.fold<double>(0, (sum, p) => sum + p.height + 2);

    final panelHeight = [
      textBlockHeight + panelPadding * 2,
      qrSize + mapSize + panelPadding * 2,
    ].reduce((a, b) => a > b ? a : b);

    final panelTop = height - panelHeight;
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width, panelHeight),
      Paint()..color = _panelColor,
    );

    // 3. Tulis baris teks di kolom kiri.
    double cursorY = panelTop + panelPadding;
    for (final p in painters) {
      p.paint(canvas, Offset(panelPadding, cursorY));
      cursorY += p.height + 2;
    }

    // 4. QR audit di kanan (selalu ada - tidak butuh jaringan).
    final qrImage = await QrPainter(
      data: data.auditQrPayload,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(color: ui.Color(0xFF000000)),
      dataModuleStyle: const QrDataModuleStyle(color: ui.Color(0xFF000000)),
    ).toImage(qrSize);

    final qrLeft = width - panelPadding - qrSize;
    final qrTop = panelTop + (panelHeight - qrSize) / 2;
    _drawWhiteBackedImage(canvas, qrImage, Offset(qrLeft, qrTop), qrSize);

    // 5. Thumbnail peta statis di sebelah kiri QR, HANYA kalau berhasil
    // diunduh sebelumnya (lihat catatan offline-first di WatermarkData).
    if (data.staticMapImageBytes != null) {
      final mapImage = await _decodeImage(data.staticMapImageBytes!);
      final mapLeft = qrLeft - panelPadding - mapSize;
      final mapTop = panelTop + (panelHeight - mapSize) / 2;
      canvas.drawImageRect(
        mapImage,
        Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble()),
        Rect.fromLTWH(mapLeft, mapTop, mapSize, mapSize),
        Paint(),
      );
    }

    // 6. Aksen garis tipis warna brand di batas atas panel - identitas
    // visual Tulap.id yang sama dengan yang dipakai di seluruh app.
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width, 4),
      Paint()..color = _accentColor,
    );

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  List<String> _buildTextLines(WatermarkData data) {
    final dateFormatted = _formatIndonesianDateTime(data.timestamp);
    final identityLine = data.nip != null && data.nip!.isNotEmpty
        ? '${data.officerName} · NIP ${data.nip}'
        : data.officerName;

    return [
      'TULAP.ID - BUKTI TUGAS LAPANGAN',
      '$identityLine · ${data.agencyName}',
      'Tugas #${data.taskId}',
      dateFormatted,
      '${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)} · ${data.plusCode}',
      if (data.address != null) data.address!,
    ];
  }

  String _formatIndonesianDateTime(DateTime timestamp) {
    // Nama hari/bulan Indonesia ditulis manual (bukan `intl` locale)
    // supaya compositor ini tidak perlu memanggil
    // `initializeDateFormatting` sendiri - caller sudah menjaminnya
    // terinisialisasi sekali di startup app untuk kebutuhan lain
    // (lihat WatermarkOverlay), tapi compositor jalan di isolate/waktu
    // yang tidak selalu terjamin sudah lewat startup itu.
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final d = timestamp;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $hh:$mm:$ss WIB';
  }

  TextPainter _buildTextPainter(String text, double fontSize, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize,
          fontWeight: text.startsWith('TULAP.ID')
              ? FontWeight.bold
              : FontWeight.normal,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  void _drawWhiteBackedImage(
    Canvas canvas,
    ui.Image image,
    Offset topLeft,
    double size,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size),
      Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size),
      Paint(),
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
