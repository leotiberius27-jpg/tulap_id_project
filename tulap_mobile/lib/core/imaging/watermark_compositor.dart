import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// WatermarkData
/// ----------------------------------------------------------------------
/// Seluruh metadata yang direkam untuk Evidence Verification Panel:
/// - Nama petugas, NIP, dan Instansi
/// - ID Tugas, Nama Tugas Lapangan
/// - Short Evidence ID yang human-readable (mis. TL-20260824-0011)
/// - Koordinat GPS (Latitude, Longitude, Plus Code, Akurasi)
/// - Timestamp pengambilan (waktu Indonesia)
/// - Payload QR Verifikasi
/// ----------------------------------------------------------------------
class WatermarkData {
  final String officerName;
  final String? nip;
  final String agencyName;
  final String taskId;
  final String? taskName;
  final String shortEvidenceId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double gpsAccuracyMeters;
  final String plusCode;
  final String? address;
  final String auditQrPayload;
  final Uint8List? staticMapImageBytes;
  final bool isOffline;
  final bool isVerified;

  const WatermarkData({
    required this.officerName,
    this.nip,
    required this.agencyName,
    required this.taskId,
    this.taskName,
    required this.shortEvidenceId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyMeters,
    required this.plusCode,
    this.address,
    required this.auditQrPayload,
    this.staticMapImageBytes,
    this.isOffline = false,
    this.isVerified = false,
  });
}

/// WatermarkCompositor
/// ----------------------------------------------------------------------
/// Engine perender "Professional Evidence Verification Panel":
/// - Membakar panel bukti institusional beresolusi tinggi di bagian bawah foto
/// - Proporsi panel adaptif (~19–23% tinggi gambar pada portrait, ~22–26% pada landscape)
/// - QR Code besar (18–22% lebar foto) dengan quiet zone putih dan error correction level M
/// - Tipografi responsif dengan penskalaan proporsional berbasis lebar foto (baseline: 1080px)
/// - Format alamat bersih 2-baris, akurasi GPS dengan kode warna visual, dan short evidence ID
/// - Bottom trust bar resmi dengan enkapsulasi data anti-tamper
/// ----------------------------------------------------------------------
class WatermarkCompositor {
  // Palet Warna Resmi Tulap.id
  static const _panelBgColor = ui.Color(0xF00A1120); // Deep Navy ~94% opacity
  static const _topAccentColor = ui.Color(0xFF006EE6); // Tulap Primary Blue
  static const _cyanAccentColor = ui.Color(0xFF38BDF8); // Cyan highlight
  static const _textWhite = ui.Color(0xFFFFFFFF);
  static const _textLight = ui.Color(0xFFE2E8F0);
  static const _textMuted = ui.Color(0xFF94A3B8);

  // Status GPS Colors
  static const _gpsGood = ui.Color(0xFF22C55E); // Green (0-10m)
  static const _gpsAccurate = ui.Color(0xFF38BDF8); // Cyan (11-25m)
  static const _gpsFair = ui.Color(0xFFF59E0B); // Amber (26-50m)
  static const _gpsWeak = ui.Color(0xFFEF4444); // Red (>50m)

  Future<Uint8List> compose({
    required Uint8List sourceImageBytes,
    required WatermarkData data,
  }) async {
    final sourceImage = await _decodeImage(sourceImageBytes);
    final width = sourceImage.width.toDouble();
    final height = sourceImage.height.toDouble();
    final isPortrait = height >= width;

    // Skala dasar berdasarkan baseline 1080px
    final scale = (width / 1080.0).clamp(0.55, 3.5);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Gambar foto asli apa adanya sebagai background
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    // 2. Hitung dimensi & padding panel bukti
    final panelPadding = 26.0 * scale;
    final qrBoxSize = isPortrait ? (width * 0.205) : (height * 0.40);
    final innerQrSize = qrBoxSize - (16.0 * scale);

    // Hitung tinggi panel yang ideal (target ~20-22% tinggi foto portrait)
    final minPanelHeight = isPortrait ? (height * 0.21) : (height * 0.26);
    final targetPanelHeight = minPanelHeight.clamp(
      230.0 * scale,
      520.0 * scale,
    );
    final panelTop = height - targetPanelHeight;

    // 3. Render Background Panel (Deep Navy + Gradien Halus di Batas Atas)
    final panelRect = Rect.fromLTWH(0, panelTop, width, targetPanelHeight);
    canvas.drawRect(panelRect, Paint()..color = _panelBgColor);

    // Top Brand Highlight Bar
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width, 4.0 * scale),
      Paint()..color = _topAccentColor,
    );

    // 4. Render Kolom Kanan: QR Code Verification Card
    final qrRight = width - panelPadding;
    final qrLeft = qrRight - qrBoxSize;
    final qrTop = panelTop + panelPadding;

    await _renderQrCard(
      canvas: canvas,
      qrLeft: qrLeft,
      qrTop: qrTop,
      qrBoxSize: qrBoxSize,
      innerQrSize: innerQrSize,
      scale: scale,
      payload: data.auditQrPayload,
      isVerified: data.isVerified,
    );

    // 5. Render Kolom Kiri: Hierarki Informasi Bukti Lapangan
    final leftColWidth = qrLeft - (panelPadding * 1.5);
    _renderMetadataColumn(
      canvas: canvas,
      left: panelPadding,
      top: panelTop + (panelPadding * 0.8),
      maxWidth: leftColWidth,
      scale: scale,
      data: data,
    );

    // 6. Render Bottom Trust Bar
    final trustBarY = height - (26.0 * scale);
    _renderTrustBar(canvas: canvas, top: trustBarY, width: width, scale: scale);

    // 7. Ekspor hasil komposisi ke PNG
    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<void> _renderQrCard({
    required Canvas canvas,
    required double qrLeft,
    required double qrTop,
    required double qrBoxSize,
    required double innerQrSize,
    required double scale,
    required String payload,
    required bool isVerified,
  }) async {
    final qrCardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(qrLeft, qrTop, qrBoxSize, qrBoxSize),
      Radius.circular(8.0 * scale),
    );

    // Background Putih & Quiet Zone QR
    canvas.drawRRect(qrCardRect, Paint()..color = const ui.Color(0xFFFFFFFF));

    // Render Gambar QR Code Resolusi Tinggi
    final qrPainter = QrPainter(
      data: payload,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        color: ui.Color(0xFF0F172A),
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: ui.Color(0xFF0F172A),
        dataModuleShape: QrDataModuleShape.square,
      ),
    );

    final qrImage = await qrPainter.toImage(innerQrSize);
    final offsetInsideCard = (qrBoxSize - innerQrSize) / 2;
    canvas.drawImage(
      qrImage,
      Offset(qrLeft + offsetInsideCard, qrTop + offsetInsideCard),
      Paint(),
    );

    // Label di bawah QR Card
    final labelText = isVerified ? '✓ TERVERIFIKASI' : 'SCAN VERIFIKASI';
    final labelPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: isVerified ? _gpsGood : _cyanAccentColor,
          fontSize: (11.5 * scale).clamp(9.0, 16.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: qrBoxSize);

    labelPainter.paint(
      canvas,
      Offset(
        qrLeft + (qrBoxSize - labelPainter.width) / 2,
        qrTop + qrBoxSize + (6.0 * scale),
      ),
    );
  }

  void _renderMetadataColumn({
    required Canvas canvas,
    required double left,
    required double top,
    required double maxWidth,
    required double scale,
    required WatermarkData data,
  }) {
    double currentY = top;

    // 1. Header Brand: TULAP.ID • BUKTI TUGAS LAPANGAN
    final brandPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'TULAP.ID  ',
            style: TextStyle(
              color: _textWhite,
              fontSize: (20.0 * scale).clamp(14.0, 30.0),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8 * scale,
            ),
          ),
          TextSpan(
            text: 'BUKTI TUGAS LAPANGAN',
            style: TextStyle(
              color: _cyanAccentColor,
              fontSize: (12.0 * scale).clamp(9.0, 18.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6 * scale,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    brandPainter.paint(canvas, Offset(left, currentY));
    currentY += brandPainter.height + (6.0 * scale);

    // 2. Nama Kegiatan / Tugas
    final taskTitle = data.taskName ?? 'Tugas #${data.taskId}';
    final taskPainter = TextPainter(
      text: TextSpan(
        text: taskTitle,
        style: TextStyle(
          color: _textWhite,
          fontSize: (17.0 * scale).clamp(12.0, 26.0),
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    taskPainter.paint(canvas, Offset(left, currentY));
    currentY += taskPainter.height + (5.0 * scale);

    // 3. Lokasi (Maksimal 2 baris bersih)
    final formattedAddress = _formatCleanAddress(data.address, data.plusCode);
    final locationPainter = TextPainter(
      text: TextSpan(
        text: '📍  $formattedAddress',
        style: TextStyle(
          color: _textLight,
          fontSize: (13.0 * scale).clamp(9.5, 19.0),
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    locationPainter.paint(canvas, Offset(left, currentY));
    currentY += locationPainter.height + (7.0 * scale);

    // 4. Baris Akurasi GPS & Timestamp
    final gpsColor = _getGpsStatusColor(data.gpsAccuracyMeters);
    final formattedTime = _formatIndonesianDateTime(data.timestamp);

    final gpsAndDatePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '◎ GPS ±${data.gpsAccuracyMeters.round()}m  ',
            style: TextStyle(
              color: gpsColor,
              fontSize: (12.5 * scale).clamp(9.0, 18.0),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '•  ◷ $formattedTime',
            style: TextStyle(
              color: _textWhite,
              fontSize: (12.0 * scale).clamp(8.5, 17.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    gpsAndDatePainter.paint(canvas, Offset(left, currentY));
    currentY += gpsAndDatePainter.height + (6.0 * scale);

    // 5. Baris ID Bukti & Nama Petugas
    final officerInfo = data.nip != null && data.nip!.isNotEmpty
        ? '${data.officerName} (NIP ${data.nip}) • ${data.agencyName}'
        : '${data.officerName} • ${data.agencyName}';

    final metadataPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'ID Bukti: ',
            style: TextStyle(
              color: _textMuted,
              fontSize: (11.5 * scale).clamp(8.0, 16.0),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '${data.shortEvidenceId}   ',
            style: TextStyle(
              color: _textWhite,
              fontSize: (12.0 * scale).clamp(8.5, 16.5),
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: 'Petugas: ',
            style: TextStyle(
              color: _textMuted,
              fontSize: (11.5 * scale).clamp(8.0, 16.0),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: officerInfo,
            style: TextStyle(
              color: _textLight,
              fontSize: (11.5 * scale).clamp(8.0, 16.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    metadataPainter.paint(canvas, Offset(left, currentY));
  }

  void _renderTrustBar({
    required Canvas canvas,
    required double top,
    required double width,
    required double scale,
  }) {
    // Garis Separator Halus
    canvas.drawLine(
      Offset(20.0 * scale, top),
      Offset(width - (20.0 * scale), top),
      Paint()
        ..color = const ui.Color(0x33FFFFFF)
        ..strokeWidth = 0.8 * scale,
    );

    // Teks Trust Bar
    final trustPainter = TextPainter(
      text: TextSpan(
        text:
            '🛡 Direkam otomatis oleh Tulap.id  •  Data asli terproteksi SHA-256 & dapat diverifikasi via QR',
        style: TextStyle(
          color: _textMuted,
          fontSize: (10.0 * scale).clamp(7.5, 14.0),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - (40.0 * scale));

    trustPainter.paint(canvas, Offset(22.0 * scale, top + (6.0 * scale)));
  }

  ui.Color _getGpsStatusColor(double accuracyMeters) {
    if (accuracyMeters <= 10.0) return _gpsGood;
    if (accuracyMeters <= 25.0) return _gpsAccurate;
    if (accuracyMeters <= 50.0) return _gpsFair;
    return _gpsWeak;
  }

  String _formatCleanAddress(String? address, String plusCode) {
    if (address == null || address.trim().isEmpty) {
      return plusCode.isNotEmpty ? plusCode : 'Lokasi Terverifikasi GPS';
    }

    // Pisahkan koma untuk merapikan alamat panjang
    final parts = address
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) {
      return address;
    }

    // Ambil 2 segmen pertama untuk Baris 1, dan 2 segmen berikutnya untuk Baris 2
    final line1 = parts.take(2).join(', ');
    final line2 = parts.skip(2).take(2).join(', ');
    return '$line1, $line2';
  }

  String _formatIndonesianDateTime(DateTime timestamp) {
    const months = [
      'Agu',
      'Agu',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final d = timestamp.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? months[d.month - 1]
        : 'Agu';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '${d.day} $monthName ${d.year} • $hh:$mm:$ss WIT';
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
