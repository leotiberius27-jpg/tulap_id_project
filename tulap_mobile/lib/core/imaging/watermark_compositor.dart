import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../../features/geotag_camera/domain/entities/watermark_template_entity.dart';
import '../geo/mini_map_renderer.dart';
import '../qr/qr_location_generator.dart';

/// WatermarkData
/// ----------------------------------------------------------------------
/// Data terpadu untuk merender stamp visual bukti geotag kegiatan lapangan.
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
  final double? altitude;
  final double? heading;
  final String plusCode;
  final String? address;
  final String? auditQrPayload;
  final Uint8List? staticMapImageBytes;
  final bool isOffline;
  final bool isVerified;
  final StampConfiguration? configuration;

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
    this.altitude,
    this.heading,
    required this.plusCode,
    this.address,
    this.auditQrPayload,
    this.staticMapImageBytes,
    this.isOffline = false,
    this.isVerified = false,
    this.configuration,
  });
}

/// WatermarkCompositor
/// ----------------------------------------------------------------------
/// Reusable Responsive Template Engine untuk merender Geotag Evidence Stamp:
/// - Mendukung 6 Template Resmi (Klasik, Pelaporan, Tanggal & Waktu, Lokasi + QR, Kompak, Kompas/Teknis)
/// - Penskalaan responsif berbasis lebar foto (baseline 1080px) -> tajam di 720p, 1080p, 1440p, 12MP+
/// - Mini Map kontekstual (online static map / offline procedural fallback)
/// - QR Google Maps on-device berkontras tinggi ("Buka Lokasi di Google Maps")
/// - Hierarki tipografi institusional dengan proteksi overflow alamat & nama kegiatan
/// - Palet warna resmi Tulap.id (Deep Navy ~85% opacity, Tulap Blue accent, White text)
/// ----------------------------------------------------------------------
class WatermarkCompositor {
  final QrLocationGenerator _qrGenerator;
  final MiniMapRenderer _miniMapRenderer;

  WatermarkCompositor({
    QrLocationGenerator? qrGenerator,
    MiniMapRenderer? miniMapRenderer,
  })  : _qrGenerator = qrGenerator ?? QrLocationGenerator(),
        _miniMapRenderer = miniMapRenderer ?? MiniMapRenderer();

  // Palet Warna Resmi Tulap.id
  static const _panelBgColor = ui.Color(0xD90A1120); // Deep Navy ~85% opacity
  static const _topAccentColor = ui.Color(0xFF006EE6); // Tulap Primary Blue
  static const _cyanAccentColor = ui.Color(0xFF38BDF8); // Sky Blue highlight
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
    StampConfiguration? configuration,
  }) async {
    final config = configuration ?? data.configuration ?? const StampConfiguration();
    final template = TemplateCatalog.getById(config.templateId);

    final sourceImage = await _decodeImage(sourceImageBytes);
    final width = sourceImage.width.toDouble();
    final height = sourceImage.height.toDouble();
    final isPortrait = height >= width;

    // Skala dasar berdasarkan baseline 1080px (responsif 720p - 12MP)
    final scale = (width / 1080.0).clamp(0.55, 3.5);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Gambar foto asli apa adanya sebagai latar utama
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    // 2. Hitung dimensi & tinggi panel berdasarkan template
    final panelHeightFraction = isPortrait
        ? template.panelHeightFractionPortrait
        : template.panelHeightFractionLandscape;
    final minPanelHeight = height * panelHeightFraction;
    final targetPanelHeight = minPanelHeight.clamp(
      template.isMinimal ? 150.0 * scale : 210.0 * scale,
      template.isMinimal ? 340.0 * scale : 520.0 * scale,
    );
    final panelTop = height - targetPanelHeight;

    // 3. Render Background Panel (Deep Navy semi-transparan + Top Accent Line)
    final panelRect = Rect.fromLTWH(0, panelTop, width, targetPanelHeight);
    canvas.drawRect(panelRect, Paint()..color = _panelBgColor);

    // Top Brand Highlight Bar
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width, 4.0 * scale),
      Paint()..color = _topAccentColor,
    );

    final panelPaddingH = 26.0 * scale;
    final panelPaddingV = 16.0 * scale;
    final contentWidth = width - (panelPaddingH * 2);

    // 4. Render Layout sesuai Template yang Dipilih
    await _renderTemplateLayout(
      canvas: canvas,
      left: panelPaddingH,
      top: panelTop + panelPaddingV,
      width: contentWidth,
      height: targetPanelHeight - (panelPaddingV * 2) - (24.0 * scale),
      scale: scale,
      data: data,
      config: config,
      template: template,
    );

    // 5. Render Bottom Trust Bar Ringkas
    final trustBarY = height - (22.0 * scale);
    _renderTrustBar(
      canvas: canvas,
      top: trustBarY,
      width: width,
      scale: scale,
      paddingH: panelPaddingH,
    );

    // 6. Ekspor hasil komposisi ke PNG
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

  Future<void> _renderTemplateLayout({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
    required WatermarkTemplateDefinition template,
  }) async {
    switch (template.id) {
      case 'pelaporan':
        await _renderPelaporanTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;

      case 'tanggal_waktu':
        _renderTanggalWaktuTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;

      case 'lokasi_qr':
        await _renderLokasiQrTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;

      case 'kompak':
        _renderKompakTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;

      case 'kompas_teknis':
        await _renderKompasTeknisTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;

      case 'klasik':
      default:
        await _renderKlasikTemplate(
          canvas: canvas,
          left: left,
          top: top,
          width: width,
          height: height,
          scale: scale,
          data: data,
          config: config,
        );
        break;
    }
  }

  // ====================================================================
  // 1. TEMPLATE KLASIK (Geotag Seimbang dengan Mini Map)
  // ====================================================================
  Future<void> _renderKlasikTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) async {
    final shouldShowMap = config.showMiniMap;
    final mapSize = (height * 0.9).clamp(110.0 * scale, 220.0 * scale);
    final textWidth = shouldShowMap ? width - mapSize - (16.0 * scale) : width;

    // Sisi Kanan: Mini Map
    if (shouldShowMap) {
      final mapImage = await _miniMapRenderer.renderMiniMap(
        latitude: data.latitude,
        longitude: data.longitude,
        pixelSize: mapSize.toInt(),
        staticMapBytes: data.staticMapImageBytes,
      );
      final mapLeft = left + width - mapSize;
      canvas.drawImage(mapImage, Offset(mapLeft, top + (height - mapSize) / 2), Paint());
    }

    // Sisi Kiri: Metadata Lengkap
    double currentY = top;

    // Header Brand
    currentY = _drawBrandHeader(canvas, left, currentY, textWidth, scale, 'STANDAR GEOTAG');

    // Nama Kegiatan
    if (config.showTaskName) {
      final title = data.taskName ?? 'Tugas #${data.taskId}';
      currentY = _drawTaskTitle(canvas, left, currentY, textWidth, scale, title);
    }

    // Alamat
    if (config.showLocation) {
      final addressStr = _formatCleanAddress(data.address, data.plusCode);
      currentY = _drawAddress(canvas, left, currentY, textWidth, scale, addressStr);
    }

    // Baris GPS & Waktu
    currentY = _drawGpsAndDateRow(
      canvas: canvas,
      left: left,
      top: currentY,
      maxWidth: textWidth,
      scale: scale,
      data: data,
      config: config,
    );

    // Baris Koordinat & Petugas
    if (config.showCoordinates || (config.showOfficerName && data.officerName.isNotEmpty)) {
      _drawCoordinatesAndOfficerRow(
        canvas: canvas,
        left: left,
        top: currentY,
        maxWidth: textWidth,
        scale: scale,
        data: data,
        config: config,
      );
    }
  }

  // ====================================================================
  // 2. TEMPLATE PELAPORAN (Dokumentasi Formal dengan QR Google Maps)
  // ====================================================================
  Future<void> _renderPelaporanTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) async {
    final shouldShowQr = config.showQrMaps;
    final qrBoxSize = (height * 0.85).clamp(100.0 * scale, 200.0 * scale);
    final textWidth = shouldShowQr ? width - qrBoxSize - (16.0 * scale) : width;

    // Sisi Kanan: QR Google Maps dengan Label "Google Maps"
    if (shouldShowQr) {
      final mapsUrl = _qrGenerator.buildGoogleMapsUrl(
        latitude: data.latitude,
        longitude: data.longitude,
      );
      final qrImage = await _qrGenerator.generateQrImage(
        data: mapsUrl,
        pixelSize: (qrBoxSize * 0.82).toInt(),
      );

      final qrLeft = left + width - qrBoxSize;
      final qrTop = top + (height - qrBoxSize) / 2;

      // Card QR putih kontras tinggi
      final cardRect = Rect.fromLTWH(qrLeft, qrTop, qrBoxSize, qrBoxSize);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, Radius.circular(12.0 * scale)),
        Paint()..color = const ui.Color(0xFF0F172A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, Radius.circular(12.0 * scale)),
        Paint()
          ..color = const ui.Color(0x4038BDF8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );

      final qrInnerLeft = qrLeft + (qrBoxSize - (qrBoxSize * 0.82)) / 2;
      canvas.drawImage(qrImage, Offset(qrInnerLeft, qrTop + (4.0 * scale)), Paint());

      // Label Bawah QR: "Google Maps"
      final labelPainter = TextPainter(
        text: TextSpan(
          text: 'Google Maps',
          style: TextStyle(
            color: _cyanAccentColor,
            fontSize: (9.5 * scale).clamp(7.5, 14.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: qrBoxSize);
      labelPainter.paint(
        canvas,
        Offset(qrLeft + (qrBoxSize - labelPainter.width) / 2, qrTop + qrBoxSize - (16.0 * scale)),
      );
    }

    // Sisi Kiri: Data Institusi & Bukti Resmi
    double currentY = top;
    currentY = _drawBrandHeader(canvas, left, currentY, textWidth, scale, 'DOKUMENTASI RESMI');

    if (config.showTaskName) {
      currentY = _drawTaskTitle(canvas, left, currentY, textWidth, scale, data.taskName ?? 'Tugas #${data.taskId}');
    }

    if (config.showLocation) {
      currentY = _drawAddress(canvas, left, currentY, textWidth, scale, _formatCleanAddress(data.address, data.plusCode));
    }

    // Baris Evidence ID & Timestamp
    currentY = _drawEvidenceIdAndDateRow(canvas, left, currentY, textWidth, scale, data, config);

    // Baris Petugas & Instansi
    if (config.showOfficerName) {
      final officerInfo = data.nip != null && data.nip!.isNotEmpty
          ? '${data.officerName} (NIP ${data.nip}) • ${data.agencyName}'
          : '${data.officerName} • ${data.agencyName}';
      _drawSingleLineText(canvas, left, currentY, textWidth, scale, 'Petugas: $officerInfo', _textLight);
    }
  }

  // ====================================================================
  // 3. TEMPLATE TANGGAL & WAKTU (Minimalis Elegan)
  // ====================================================================
  void _renderTanggalWaktuTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) {
    double currentY = top;

    // Header Jam & Tanggal Besar
    final localDt = data.timestamp.toLocal();
    final timeStr =
        '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
    final dateStr = _formatIndonesianDateOnly(localDt);

    final bigTimePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$timeStr  ',
            style: TextStyle(
              color: _textWhite,
              fontSize: (26.0 * scale).clamp(18.0, 38.0),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0 * scale,
            ),
          ),
          TextSpan(
            text: dateStr,
            style: TextStyle(
              color: _cyanAccentColor,
              fontSize: (16.0 * scale).clamp(11.0, 24.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    bigTimePainter.paint(canvas, Offset(left, currentY));
    currentY += bigTimePainter.height + (6.0 * scale);

    // Lokasi & Akurasi
    if (config.showLocation) {
      final addressStr = _formatCleanAddress(data.address, data.plusCode);
      currentY = _drawAddress(canvas, left, currentY, width, scale, addressStr);
    }

    if (config.showGpsAccuracy) {
      final gpsColor = _getGpsStatusColor(data.gpsAccuracyMeters);
      _drawSingleLineText(
        canvas,
        left,
        currentY,
        width,
        scale,
        'GPS ±${data.gpsAccuracyMeters.round()} m • TULAP.ID',
        gpsColor,
      );
    }
  }

  // ====================================================================
  // 4. TEMPLATE LOKASI + QR (Navigasi Lapangan Presisi)
  // ====================================================================
  Future<void> _renderLokasiQrTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) async {
    final qrBoxSize = (height * 0.9).clamp(110.0 * scale, 210.0 * scale);
    final textWidth = width - qrBoxSize - (16.0 * scale);

    // Sisi Kanan: QR Google Maps
    final mapsUrl = _qrGenerator.buildGoogleMapsUrl(
      latitude: data.latitude,
      longitude: data.longitude,
    );
    final qrImage = await _qrGenerator.generateQrImage(
      data: mapsUrl,
      pixelSize: (qrBoxSize * 0.82).toInt(),
    );

    final qrLeft = left + width - qrBoxSize;
    final qrTop = top + (height - qrBoxSize) / 2;

    final cardRect = Rect.fromLTWH(qrLeft, qrTop, qrBoxSize, qrBoxSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, Radius.circular(12.0 * scale)),
      Paint()..color = const ui.Color(0xFF0F172A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, Radius.circular(12.0 * scale)),
      Paint()
        ..color = const ui.Color(0x4038BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    final qrInnerLeft = qrLeft + (qrBoxSize - (qrBoxSize * 0.82)) / 2;
    canvas.drawImage(qrImage, Offset(qrInnerLeft, qrTop + (4.0 * scale)), Paint());

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Buka Lokasi',
        style: TextStyle(
          color: _cyanAccentColor,
          fontSize: (9.5 * scale).clamp(7.5, 14.0),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: qrBoxSize);
    labelPainter.paint(
      canvas,
      Offset(qrLeft + (qrBoxSize - labelPainter.width) / 2, qrTop + qrBoxSize - (16.0 * scale)),
    );

    // Sisi Kiri: Navigasi Lapangan
    double currentY = top;
    currentY = _drawBrandHeader(canvas, left, currentY, textWidth, scale, 'NAVIGASI LAPANGAN');

    if (config.showLocation) {
      currentY = _drawAddress(canvas, left, currentY, textWidth, scale, _formatCleanAddress(data.address, data.plusCode));
    }

    if (config.showCoordinates) {
      final coordStr =
          '${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)}';
      currentY = _drawSingleLineText(
        canvas,
        left,
        currentY,
        textWidth,
        scale,
        '🌐 $coordStr',
        _textWhite,
      );
    }

    _drawGpsAndDateRow(
      canvas: canvas,
      left: left,
      top: currentY,
      maxWidth: textWidth,
      scale: scale,
      data: data,
      config: config,
    );
  }

  // ====================================================================
  // 5. TEMPLATE KOMPAK (Panel Ramping Teringkas)
  // ====================================================================
  void _renderKompakTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) {
    double currentY = top;

    // Baris 1: TULAP.ID • Nama Tugas
    final title = data.taskName ?? 'Tugas #${data.taskId}';
    final line1Painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'TULAP.ID • ',
            style: TextStyle(
              color: _cyanAccentColor,
              fontSize: (14.0 * scale).clamp(10.0, 20.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: title,
            style: TextStyle(
              color: _textWhite,
              fontSize: (14.0 * scale).clamp(10.0, 20.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width);
    line1Painter.paint(canvas, Offset(left, currentY));
    currentY += line1Painter.height + (4.0 * scale);

    // Baris 2: Alamat Singkat
    if (config.showLocation) {
      final addr = _formatCleanAddress(data.address, data.plusCode);
      currentY = _drawSingleLineText(canvas, left, currentY, width, scale, '📍 $addr', _textLight);
    }

    // Baris 3: GPS & Waktu
    _drawGpsAndDateRow(
      canvas: canvas,
      left: left,
      top: currentY,
      maxWidth: width,
      scale: scale,
      data: data,
      config: config,
    );
  }

  // ====================================================================
  // 6. TEMPLATE KOMPAS / TEKNIS (Survey Teknis & Elevasi)
  // ====================================================================
  Future<void> _renderKompasTeknisTemplate({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) async {
    double currentY = top;
    currentY = _drawBrandHeader(canvas, left, currentY, width, scale, 'INSPEKSI TEKNIS');

    // Baris Kompas & Elevasi
    final headingDeg = data.heading != null ? '${data.heading!.round()}° ${_getHeadingDirection(data.heading!)}' : 'N/A';
    final altStr = data.altitude != null ? '${data.altitude!.round()} m dpl' : '-- m';

    final compassPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '🧭 $headingDeg  ',
            style: TextStyle(
              color: _cyanAccentColor,
              fontSize: (13.5 * scale).clamp(9.5, 19.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '•  ⛰ Elevasi: $altStr  ',
            style: TextStyle(
              color: _textWhite,
              fontSize: (13.0 * scale).clamp(9.0, 18.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '•  GPS ±${data.gpsAccuracyMeters.round()} m',
            style: TextStyle(
              color: _getGpsStatusColor(data.gpsAccuracyMeters),
              fontSize: (13.0 * scale).clamp(9.0, 18.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    compassPainter.paint(canvas, Offset(left, currentY));
    currentY += compassPainter.height + (5.0 * scale);

    // Koordinat & Waktu
    if (config.showCoordinates) {
      final coordStr =
          '🌐 ${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)}';
      currentY = _drawSingleLineText(canvas, left, currentY, width, scale, coordStr, _textLight);
    }

    if (config.showLocation) {
      final addr = _formatCleanAddress(data.address, data.plusCode);
      _drawAddress(canvas, left, currentY, width, scale, addr);
    }
  }

  // ====================================================================
  // HELPER DRAWING FUNCTIONS
  // ====================================================================
  double _drawBrandHeader(
    Canvas canvas,
    double left,
    double top,
    double maxWidth,
    double scale,
    String tagText,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'TULAP.ID  ',
            style: TextStyle(
              color: _textWhite,
              fontSize: (18.0 * scale).clamp(12.0, 26.0),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8 * scale,
            ),
          ),
          TextSpan(
            text: '•  $tagText',
            style: TextStyle(
              color: _cyanAccentColor,
              fontSize: (11.5 * scale).clamp(8.5, 17.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6 * scale,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  double _drawTaskTitle(
    Canvas canvas,
    double left,
    double top,
    double maxWidth,
    double scale,
    String title,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: _textWhite,
          fontSize: (15.5 * scale).clamp(11.0, 23.0),
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  double _drawAddress(
    Canvas canvas,
    double left,
    double top,
    double maxWidth,
    double scale,
    String address,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: '📍 $address',
        style: TextStyle(
          color: _textLight,
          fontSize: (12.5 * scale).clamp(9.0, 18.0),
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (5.0 * scale);
  }

  double _drawGpsAndDateRow({
    required Canvas canvas,
    required double left,
    required double top,
    required double maxWidth,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) {
    final gpsColor = _getGpsStatusColor(data.gpsAccuracyMeters);
    final formattedTime = _formatIndonesianDateTime(data.timestamp);

    final painter = TextPainter(
      text: TextSpan(
        children: [
          if (config.showGpsAccuracy)
            TextSpan(
              text: 'GPS ±${data.gpsAccuracyMeters.round()} m  ',
              style: TextStyle(
                color: gpsColor,
                fontSize: (12.0 * scale).clamp(8.5, 17.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (config.showDate || config.showTime)
            TextSpan(
              text: '•  $formattedTime',
              style: TextStyle(
                color: _textWhite,
                fontSize: (11.5 * scale).clamp(8.0, 16.5),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  double _drawCoordinatesAndOfficerRow({
    required Canvas canvas,
    required double left,
    required double top,
    required double maxWidth,
    required double scale,
    required WatermarkData data,
    required StampConfiguration config,
  }) {
    final coordStr =
        '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    final officerStr = data.officerName.isNotEmpty ? data.officerName : '';

    final painter = TextPainter(
      text: TextSpan(
        children: [
          if (config.showCoordinates)
            TextSpan(
              text: '$coordStr   ',
              style: TextStyle(
                color: _textMuted,
                fontSize: (11.0 * scale).clamp(8.0, 15.5),
                fontFamily: 'monospace',
              ),
            ),
          if (config.showOfficerName && officerStr.isNotEmpty)
            TextSpan(
              text: '•  $officerStr',
              style: TextStyle(
                color: _textLight,
                fontSize: (11.5 * scale).clamp(8.0, 16.0),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  double _drawEvidenceIdAndDateRow(
    Canvas canvas,
    double left,
    double top,
    double maxWidth,
    double scale,
    WatermarkData data,
    StampConfiguration config,
  ) {
    final formattedTime = _formatIndonesianDateTime(data.timestamp);

    final painter = TextPainter(
      text: TextSpan(
        children: [
          if (config.showEvidenceId) ...[
            TextSpan(
              text: 'ID: ',
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
          ],
          TextSpan(
            text: '•  $formattedTime',
            style: TextStyle(
              color: _textLight,
              fontSize: (11.5 * scale).clamp(8.0, 16.0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  double _drawSingleLineText(
    Canvas canvas,
    double left,
    double top,
    double maxWidth,
    double scale,
    String text,
    ui.Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: (12.0 * scale).clamp(8.5, 16.5),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(left, top));
    return top + painter.height + (4.0 * scale);
  }

  void _renderTrustBar({
    required Canvas canvas,
    required double top,
    required double width,
    required double scale,
    required double paddingH,
  }) {
    canvas.drawLine(
      Offset(paddingH, top),
      Offset(width - paddingH, top),
      Paint()
        ..color = const ui.Color(0x33FFFFFF)
        ..strokeWidth = 0.8 * scale,
    );

    final trustPainter = TextPainter(
      text: TextSpan(
        text: '🛡 Bukti Digital Resmi Tulap.id  •  Integritas Terverifikasi SHA-256',
        style: TextStyle(
          color: _textMuted,
          fontSize: (9.5 * scale).clamp(7.0, 13.5),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - (paddingH * 2));

    trustPainter.paint(canvas, Offset(paddingH, top + (4.0 * scale)));
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

    final parts = address
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) {
      return address;
    }

    final line1 = parts.take(2).join(', ');
    final line2 = parts.skip(2).take(2).join(', ');
    return '$line1, $line2';
  }

  String _formatIndonesianDateTime(DateTime timestamp) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final d = timestamp.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? months[d.month - 1]
        : 'Agu';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} $monthName ${d.year} • $hh:$mm';
  }

  String _formatIndonesianDateOnly(DateTime timestamp) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final d = timestamp.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? months[d.month - 1]
        : 'Agustus';
    return '${d.day} $monthName ${d.year}';
  }

  String _getHeadingDirection(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'U (Utara)';
    if (normalized >= 22.5 && normalized < 67.5) return 'TL (Timur Laut)';
    if (normalized >= 67.5 && normalized < 112.5) return 'T (Timur)';
    if (normalized >= 112.5 && normalized < 157.5) return 'TG (Tenggara)';
    if (normalized >= 157.5 && normalized < 202.5) return 'S (Selatan)';
    if (normalized >= 202.5 && normalized < 247.5) return 'BD (Barat Daya)';
    if (normalized >= 247.5 && normalized < 292.5) return 'B (Barat)';
    return 'BL (Barat Laut)';
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
