import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';
import '../geo/mini_map_renderer.dart';
import '../qr/qr_location_generator.dart';
import '../widgets/real_mini_map_preview.dart';

/// GeotagWatermarkData
/// ----------------------------------------------------------------------
/// Model data terparameterisasi untuk komponen watermark/overlay geotag
/// kamera - dipakai IDENTIK oleh [GeotagWatermarkOverlay] (widget live di
/// atas viewfinder / layar review) MAUPUN [GeotagWatermarkCompositor]
/// (pembakar watermark permanen ke byte foto asli saat capture), supaya
/// keduanya selalu tampil PERSIS sama secara proporsional.
/// ----------------------------------------------------------------------
class GeotagWatermarkData {
  final double latitude;
  final double longitude;

  /// Baris 1 (header/makro): lokasi administratif utama, mis.
  /// "Kecamatan Mimika Baru, Papua Tengah, Indonesia 🇮🇩".
  final String addressLine1;

  /// Baris 2 (detail): nama tempat/PO, jalan, kelurahan, kecamatan,
  /// kabupaten, provinsi, & kode pos LENGKAP tanpa dipotong.
  final String addressLine2;

  final DateTime timestamp;
  final String logoAssetPath;
  final String qrData;
  final String appName;

  /// Byte peta statis yang SUDAH tersedia (hasil fetch sebelumnya).
  final Uint8List? mapImageBytes;

  /// ATAU Future byte peta statis yang sudah dimulai (non-awaited) SEBELUM
  /// shutter kamera ditekan - lihat StaticMapFetcher &
  /// GeotagCameraRepositoryImpl. [GeotagWatermarkCompositor.burn] menunggu
  /// Future ini (dengan timeout) setelah foto sudah dijepret, supaya
  /// jaringan lambat/mati TIDAK PERNAH menunda shutter.
  final Future<Uint8List?>? mapImageBytesFuture;

  const GeotagWatermarkData({
    required this.latitude,
    required this.longitude,
    required this.addressLine1,
    required this.addressLine2,
    required this.timestamp,
    this.logoAssetPath = 'assets/images/logo.png',
    required this.qrData,
    this.appName = 'Tulap.id',
    this.mapImageBytes,
    this.mapImageBytesFuture,
  });
}

/// GeotagWatermarkOverlay
/// ----------------------------------------------------------------------
/// Komponen widget overlay geotag watermark gaya "GPS Map Camera":
/// - Kartu rounded translucent (hitam ~65% opacity, radius 14) 3-kolom:
///   peta persegi (kiri) - hirarki teks alamat/koordinat/waktu (tengah) -
///   kotak QR putih persegi (kanan).
/// - Badge aplikasi berbentuk kapsul MENGAMBANG di pojok kanan-atas kartu,
///   menonjol sedikit ke luar/atas tepi kartu (bukan di dalam panel).
///
/// Dipakai live di atas CameraPreview (viewfinder) MAUPUN di layar review
/// foto/video - satu komponen, satu sumber kebenaran visual.
/// ----------------------------------------------------------------------
class GeotagWatermarkOverlay extends StatelessWidget {
  final GeotagWatermarkData data;

  /// Override manual opsional - biarkan null (default) supaya ukuran
  /// dihitung otomatis secara proporsional dari lebar kartu yang benar-benar
  /// tersedia (lihat [_buildCard]), sesuai rasio pada referensi
  /// Referensi/Mobile/Camera/02.jpeg (peta ~20% lebar kartu, QR ~28% -
  /// QR SEDIKIT LEBIH BESAR dari peta, bukan lebih kecil) - supaya kolom
  /// teks di tengah selalu kebagian ruang cukup dan alamat tidak pernah
  /// terpotong/terlalu sempit di layar sekecil apa pun.
  final double? mapSize;
  final double? qrSize;
  final VoidCallback? onQrTap;

  const GeotagWatermarkOverlay({
    super.key,
    required this.data,
    this.mapSize,
    this.qrSize,
    this.onQrTap,
  });

  static const double _cardRadius = 12;
  static const double _cardPadding = 10;
  static const double _badgeOverhang = 12;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ruang ekstra di atas supaya badge mengambang tidak terpotong Stack.
      padding: const EdgeInsets.only(top: _badgeOverhang),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCard(),
          // Badge mengambang - top NEGATIF supaya badge benar-benar berada
          // DI ATAS/LUAR tepi kartu (menonjol keluar), separuh tumpang
          // tindih ke dalam kartu, BUKAN duduk rata di y=0 kartu (yang
          // sebelumnya bikin badge bertabrakan/menimpa kotak QR di
          // bawahnya - keduanya sama-sama di pojok kanan-atas kartu).
          Positioned(
            top: -_badgeOverhang,
            right: 16,
            child: _buildFloatingBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardContentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width - 48;
          final resolvedMapSize =
              mapSize ?? (cardContentWidth * 0.15).clamp(44.0, 84.0);
          final resolvedQrSize =
              qrSize ?? (cardContentWidth * 0.19).clamp(50.0, 96.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RealMiniMapPreview(
                latitude: data.latitude,
                longitude: data.longitude,
                size: resolvedMapSize,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildTextColumn()),
              const SizedBox(width: 10),
              _buildQrBox(resolvedQrSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Baris 1: Header/makro (lokasi administratif utama + bendera)
        Text(
          data.addressLine1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Baris 2: Detail alamat LENGKAP - sengaja TANPA maxLines/ellipsis
        // supaya selalu terbaca utuh, tidak pernah terpotong "…".
        Text(
          data.addressLine2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        // Baris 3: Koordinat teknis (monospace)
        Text(
          'Lat ${data.latitude.toStringAsFixed(6)}°  Long ${data.longitude.toStringAsFixed(6)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Baris 4: Timestamp (hari, tanggal DD/MM/YYYY, jam 12-hour AM/PM)
        Text(
          _formatDayDateTime(data.timestamp),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQrBox(double resolvedQrSize) {
    final box = Container(
      width: resolvedQrSize,
      height: resolvedQrSize,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: QrImageView(
        data: data.qrData,
        version: QrVersions.auto,
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
      ),
    );
    if (onQrTap == null) return box;
    return GestureDetector(onTap: onQrTap, child: box);
  }

  Widget _buildFloatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              data.logoAssetPath,
              width: 12,
              height: 12,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            data.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static const _days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  static String _formatDayDateTime(DateTime timestamp) {
    final d = timestamp.toLocal();
    final day = _days[d.weekday % 7];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hh = hour12.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$day, $dd/$mm/${d.year} $hh:$min $ampm';
  }
}

/// GeotagWatermarkCompositor
/// ----------------------------------------------------------------------
/// Fungsi rendering canvas untuk membakar (burn) layout
/// [GeotagWatermarkOverlay] ke dalam byte foto asli saat capture -
/// menghasilkan file bukti final yang identik secara visual & proporsional
/// dengan tampilan live di atas viewfinder (satu spesifikasi layout,
/// dua jalur render: widget Flutter untuk live preview, Canvas untuk
/// dibakar permanen ke piksel foto).
/// ----------------------------------------------------------------------
class GeotagWatermarkCompositor {
  final QrLocationGenerator _qrGenerator;
  final MiniMapRenderer _miniMapRenderer;

  GeotagWatermarkCompositor({
    QrLocationGenerator? qrGenerator,
    MiniMapRenderer? miniMapRenderer,
  })  : _qrGenerator = qrGenerator ?? QrLocationGenerator(),
        _miniMapRenderer = miniMapRenderer ?? MiniMapRenderer();

  static ui.Image? _cachedLogoImage;
  static String? _cachedLogoAssetPath;

  static const _days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  /// Membakar watermark ke [sourceImageBytes] dan mengembalikan PNG bytes
  /// hasil akhir (foto asli + kartu + badge, ukuran piksel identik sumber).
  Future<Uint8List> burnToBytes({
    required Uint8List sourceImageBytes,
    required GeotagWatermarkData data,
  }) async {
    final image = await burn(sourceImageBytes: sourceImageBytes, data: data);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> burn({
    required Uint8List sourceImageBytes,
    required GeotagWatermarkData data,
  }) async {
    Uint8List? mapBytes = data.mapImageBytes;
    if (mapBytes == null && data.mapImageBytesFuture != null) {
      try {
        mapBytes = await data.mapImageBytesFuture!.timeout(const Duration(seconds: 3));
      } catch (_) {
        mapBytes = null;
      }
    }

    final sourceImage = await _decodeImage(sourceImageBytes);
    final width = sourceImage.width.toDouble();
    final height = sourceImage.height.toDouble();
    final scale = (width / 1080.0).clamp(0.55, 3.5);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    // --- Dimensi kartu mengambang (margin dari tepi foto di semua sisi) ---
    final marginH = 14.0 * scale;
    final marginBottom = 18.0 * scale;
    final cardPadding = 10.0 * scale;
    final cardRadius = Radius.circular(12.0 * scale);
    final cardWidth = width - (marginH * 2);
    final columnGap = 10.0 * scale;

    // Rasio PERSIS mengikuti referensi Referensi/Mobile/Camera/02.jpeg: QR
    // SEDIKIT LEBIH BESAR dari peta (bukan lebih kecil) - dihitung sebagai
    // proporsi independen dari lebar kartu, IDENTIK dengan
    // GeotagWatermarkOverlay._buildCard() di atas supaya live preview &
    // hasil bakar foto benar-benar sama.
    final mapSize = (cardWidth * 0.15).clamp(70.0 * scale, 170.0 * scale);
    final qrSize = (cardWidth * 0.19).clamp(80.0 * scale, 190.0 * scale);
    final textWidth = cardWidth - mapSize - qrSize - (columnGap * 2) - (cardPadding * 2);

    // --- Ukur seluruh baris teks LEBIH DULU (alamat lengkap tanpa batas
    // baris) supaya tinggi kartu bisa dihitung dinamis dan alamat panjang
    // apa pun tetap tampil utuh, tidak terpotong "…".
    final line1Painter = TextPainter(
      text: TextSpan(
        text: data.addressLine1,
        style: TextStyle(
          color: Colors.white,
          fontSize: (11.5 * scale).clamp(8.5, 16.0),
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);

    final line2Painter = TextPainter(
      text: TextSpan(
        text: data.addressLine2,
        style: TextStyle(
          color: Colors.white,
          fontSize: (8.5 * scale).clamp(6.5, 12.5),
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);

    final line3Painter = TextPainter(
      text: TextSpan(
        text: 'Lat ${data.latitude.toStringAsFixed(6)}°  Long ${data.longitude.toStringAsFixed(6)}°',
        style: TextStyle(
          color: Colors.white,
          fontSize: (9.0 * scale).clamp(7.0, 13.0),
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);

    final line4Painter = TextPainter(
      text: TextSpan(
        text: _formatDayDateTime(data.timestamp),
        style: TextStyle(
          color: Colors.white,
          fontSize: (9.0 * scale).clamp(7.0, 13.0),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);

    final textColumnHeight = line1Painter.height +
        (4.0 * scale) +
        line2Painter.height +
        (5.0 * scale) +
        line3Painter.height +
        (2.0 * scale) +
        line4Painter.height;

    final contentHeight = math.max(mapSize, math.max(qrSize, textColumnHeight));
    final cardHeight = contentHeight + (cardPadding * 2);

    final cardTop = (height - marginBottom - cardHeight).clamp(0.0, height);
    final cardLeft = marginH;
    final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);

    // --- 1. Kartu translucent rounded (hitam ~65% opacity) ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, cardRadius),
      Paint()..color = const Color.fromRGBO(0, 0, 0, 0.65),
    );

    // --- 2. Kolom Kiri: Peta (nyata jika tersedia, prosedural jika offline) ---
    final mapTop = cardTop + cardPadding;
    final mapLeft = cardLeft + cardPadding;
    final mapImage = await _miniMapRenderer.renderMiniMap(
      latitude: data.latitude,
      longitude: data.longitude,
      pixelSize: mapSize.toInt(),
      staticMapBytes: mapBytes,
    );
    canvas.drawImage(mapImage, Offset(mapLeft, mapTop), Paint());

    // --- 3. Kolom Tengah: Hirarki Teks ---
    final textLeft = mapLeft + mapSize + columnGap;
    var textY = mapTop;
    line1Painter.paint(canvas, Offset(textLeft, textY));
    textY += line1Painter.height + (4.0 * scale);
    line2Painter.paint(canvas, Offset(textLeft, textY));
    textY += line2Painter.height + (5.0 * scale);
    line3Painter.paint(canvas, Offset(textLeft, textY));
    textY += line3Painter.height + (2.0 * scale);
    line4Painter.paint(canvas, Offset(textLeft, textY));

    // --- 4. Kolom Kanan: Kotak QR putih ---
    final qrLeft = cardLeft + cardWidth - cardPadding - qrSize;
    final qrTop = mapTop;
    final qrRect = Rect.fromLTWH(qrLeft, qrTop, qrSize, qrSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(qrRect, Radius.circular(8.0 * scale)),
      Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    final qrImage = await _qrGenerator.generateQrImage(
      data: data.qrData,
      pixelSize: (qrSize * 0.82).toInt(),
    );
    final qrInner = (qrSize - (qrSize * 0.82)) / 2;
    canvas.drawImage(qrImage, Offset(qrLeft + qrInner, qrTop + qrInner), Paint());

    // --- 5. Badge Mengambang: Logo + Nama Aplikasi (pojok kanan-atas kartu,
    // menonjol keluar/atas tepi kartu - digambar TERAKHIR supaya di atas) ---
    await _drawFloatingBadge(
      canvas: canvas,
      data: data,
      scale: scale,
      cardTop: cardTop,
      cardRight: cardLeft + cardWidth,
    );

    final picture = recorder.endRecording();
    return picture.toImage(sourceImage.width, sourceImage.height);
  }

  Future<void> _drawFloatingBadge({
    required Canvas canvas,
    required GeotagWatermarkData data,
    required double scale,
    required double cardTop,
    required double cardRight,
  }) async {
    final logoImage = await _loadLogoImage(data.logoAssetPath);
    final badgePaddingH = 8.0 * scale;
    final badgePaddingV = 4.0 * scale;
    final logoSize = (12.0 * scale).clamp(9.0, 18.0);
    final logoGap = 4.0 * scale;

    final textPainter = TextPainter(
      text: TextSpan(
        text: data.appName,
        style: TextStyle(
          color: Colors.white,
          fontSize: (8.5 * scale).clamp(6.5, 12.5),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final contentWidth = (logoImage != null ? logoSize + logoGap : 0.0) + textPainter.width;
    final contentHeight = math.max(logoImage != null ? logoSize : 0.0, textPainter.height);
    final badgeWidth = contentWidth + (badgePaddingH * 2);
    final badgeHeight = contentHeight + (badgePaddingV * 2);

    final badgeRightInset = 16.0 * scale;
    final badgeLeft = cardRight - badgeRightInset - badgeWidth;
    // Mengambang: separuh tinggi badge menonjol di ATAS tepi kartu, sisanya
    // sedikit tumpang tindih ke dalam kartu - sesuai spesifikasi "offset
    // sedikit ke atas luar kartu".
    final badgeTop = cardTop - (badgeHeight * 0.55);
    final badgeRect = Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, Radius.circular(badgeHeight / 2));

    canvas.drawRRect(badgeRRect, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.55));
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale
        ..color = Colors.white.withValues(alpha: 0.25),
    );

    var contentLeft = badgeLeft + badgePaddingH;
    final contentTop = badgeTop + badgePaddingV;
    if (logoImage != null) {
      final logoTop = contentTop + (contentHeight - logoSize) / 2;
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        Rect.fromLTWH(contentLeft, logoTop, logoSize, logoSize),
        Paint()..filterQuality = FilterQuality.high,
      );
      contentLeft += logoSize + logoGap;
    }
    final textTop = contentTop + (contentHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(contentLeft, textTop));
  }

  /// Memuat & men-decode asset logo sebagai [ui.Image] untuk digambar
  /// langsung di Canvas - di-cache di memori setelah pertama kali dimuat.
  Future<ui.Image?> _loadLogoImage(String assetPath) async {
    if (_cachedLogoImage != null && _cachedLogoAssetPath == assetPath) {
      return _cachedLogoImage;
    }
    try {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _cachedLogoImage = frame.image;
      _cachedLogoAssetPath = assetPath;
      return frame.image;
    } catch (_) {
      // Aset gagal dimuat - jangan pernah menjatuhkan seluruh proses
      // compose foto hanya karena logo tidak tampil.
      return null;
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static String _formatDayDateTime(DateTime timestamp) {
    final d = timestamp.toLocal();
    final day = _days[d.weekday % 7];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hh = hour12.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$day, $dd/$mm/${d.year} $hh:$min $ampm';
  }
}
