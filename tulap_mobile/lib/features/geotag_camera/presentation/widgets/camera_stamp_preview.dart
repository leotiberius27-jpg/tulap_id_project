import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/watermark_template_entity.dart';

/// CameraStampPreview
/// ----------------------------------------------------------------------
/// Widget live preview stamp/watermark yang melayang di atas feed kamera
/// Sesuai referensi visual 01.jpeg:
/// - Mini Map Google di sisi kiri dengan pin merah dan logo Google
/// - Teks alamat lengkap, Plus Code, koordinat presisi, dan waktu dengan nama hari
/// - QR Code Google Maps di sisi kanan dengan badge header "GPS Map Camera"
/// - Latar semi-transparan gelap yang menyatu elegan dengan viewfinder
/// ----------------------------------------------------------------------
class CameraStampPreview extends StatelessWidget {
  final String taskName;
  final String officerName;
  final String? nip;
  final String agencyName;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? altitude;
  final double? heading;
  final String? address;
  final DateTime currentTime;
  final StampConfiguration stampConfig;

  const CameraStampPreview({
    super.key,
    required this.taskName,
    required this.officerName,
    this.nip,
    required this.agencyName,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.altitude,
    this.heading,
    this.address,
    required this.currentTime,
    required this.stampConfig,
  });

  @override
  Widget build(BuildContext context) {
    final template = TemplateCatalog.getById(stampConfig.templateId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xD9000000), // Rich black, 85% opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: _buildTemplateBody(context, template),
      ),
    );
  }

  Widget _buildTemplateBody(
    BuildContext context,
    WatermarkTemplateDefinition template,
  ) {
    switch (template.id) {
      case 'pelaporan':
        return _buildPelaporanLayout();
      case 'tanggal_waktu':
        return _buildTanggalWaktuLayout();
      case 'lokasi_qr':
        return _buildLokasiQrLayout();
      case 'kompak':
        return _buildKompakLayout();
      case 'kompas_teknis':
        return _buildKompasTeknisLayout();
      case 'klasik':
      default:
        return _buildKlasikLayout();
    }
  }

  // 1. KLASIK: Layout Penuh Presisi Sesuai Referensi 01.jpeg
  // [Mini Map] [Judul Wilayah, Alamat/PlusCode, Koordinat, Hari/Tanggal/GMT] [QR GPS Camera]
  Widget _buildKlasikLayout() {
    final shouldShowMap = stampConfig.showMiniMap;
    final shouldShowQr = stampConfig.showQrMaps;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Mini Map Preview dengan Pin Merah & Logo Google (01.jpeg)
        if (shouldShowMap) ...[
          _buildMiniMapPreviewWidget(size: 68),
          const SizedBox(width: 8),
        ],

        // Sisi Tengah: Teks Wilayah, Alamat, Koordinat, Waktu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandBadge('STANDAR GEOTAG'),
              if (stampConfig.showTaskName && taskName.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (stampConfig.showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  _getDetailedAddressLine(),
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2),
              _buildGpsAndDateRow(),
              if (stampConfig.showCoordinates && latitude != null && longitude != null) ...[
                const SizedBox(height: 1),
                Text(
                  'Lat ${latitude!.toStringAsFixed(5)}°   Long ${longitude!.toStringAsFixed(5)}°',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 9.0,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Sisi Kanan: QR Code dengan Badge "Google Maps" (01.jpeg)
        if (shouldShowQr) ...[
          const SizedBox(width: 8),
          _buildQrPreviewWidget(size: 68),
        ],
      ],
    );
  }

  // 2. PELAPORAN: Dokumentasi Formal Institusi dengan QR Google Maps
  Widget _buildPelaporanLayout() {
    final shouldShowQr = stampConfig.showQrMaps;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandBadge('DOKUMENTASI RESMI'),
              if (stampConfig.showTaskName) ...[
                const SizedBox(height: 2),
                Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (stampConfig.showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  _getDetailedAddressLine(),
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2),
              _buildGpsAndDateRow(),
              if (stampConfig.showOfficerName) ...[
                const SizedBox(height: 2),
                Text(
                  'Petugas: $officerName • $agencyName',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        if (shouldShowQr) ...[
          const SizedBox(width: 8),
          _buildQrPreviewWidget(size: 68),
        ],
      ],
    );
  }

  // 3. TANGGAL & WAKTU: Minimalis Elegan
  Widget _buildTanggalWaktuLayout() {
    final hh = currentTime.hour.toString().padLeft(2, '0');
    final mm = currentTime.minute.toString().padLeft(2, '0');
    final dateStr = _formatIndonesianDateOnly(currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '$hh:$mm',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: const TextStyle(
                color: Color(0xFFFFC700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (stampConfig.showLocation) ...[
          const SizedBox(height: 2),
          Text(
            _getCleanAddress(),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 2),
        _buildGpsAndDateRow(),
      ],
    );
  }

  // 4. LOKASI + QR: Navigasi Lapangan
  Widget _buildLokasiQrLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandBadge('NAVIGASI LAPANGAN'),
              if (stampConfig.showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  _getDetailedAddressLine(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (stampConfig.showCoordinates && latitude != null && longitude != null) ...[
                const SizedBox(height: 2),
                Text(
                  '🌐 ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.white, // Koordinat: crisp white
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 2),
              _buildGpsAndDateRow(),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildQrPreviewWidget(size: 68),
      ],
    );
  }

  // 5. KOMPAK: Panel Ramping Teringkas
  Widget _buildKompakLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'TULAP.ID • ',
              style: TextStyle(
                color: Color(0xFFFFC700),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                taskName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (stampConfig.showLocation) ...[
          const SizedBox(height: 2),
          Text(
            _getCleanAddress(),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 2),
        _buildGpsAndDateRow(),
      ],
    );
  }

  // 6. KOMPAS / TEKNIS: Inspeksi & Elevasi
  Widget _buildKompasTeknisLayout() {
    final headingDeg = heading != null ? '${heading!.round()}°' : '0°';
    final altStr = altitude != null ? '${altitude!.round()} m dpl' : '-- m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrandBadge('INSPEKSI TEKNIS'),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '🧭 $headingDeg  ',
              style: const TextStyle(
                color: Color(0xFFFFC700),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '•  ⛰ Elevasi: $altStr  ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildGpsBadgeOnly(),
          ],
        ),
        if (stampConfig.showCoordinates && latitude != null && longitude != null) ...[
          const SizedBox(height: 2),
          Text(
            '🌐 ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 9.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (stampConfig.showLocation) ...[
          const SizedBox(height: 2),
          Text(
            _getDetailedAddressLine(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ====================================================================
  // HELPER WIDGETS
  // ====================================================================
  Widget _buildBrandBadge(String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'TULAP.ID  ',
          style: TextStyle(
            color: Color(0xFFFFC700), // Golden Yellow - judul kartu
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '•  $subtitle',
          style: const TextStyle(
            color: Color(0xFFFFC700),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsAndDateRow() {
    final acc = accuracyMeters != null ? '±${accuracyMeters!.round()} m' : '±-- m';
    final gpsColor = _getGpsStatusColor(accuracyMeters ?? 100);
    final timeStr = _formatIndonesianDateTime(currentTime);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stampConfig.showGpsAccuracy) ...[
          Text(
            'GPS $acc',
            style: TextStyle(
              color: gpsColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
        ],
        // Flexible + ellipsis: baris ini dirender di dalam kontainer
        // stamp preview berlebar tetap (mis. ~162px) - dikonfirmasi
        // nyata lewat live-test di perangkat fisik: teks "GPS ±Xm • Tgl
        // HH:mm:ss" bisa melebihi lebar itu hanya oleh SEPERSEKIAN
        // pixel (0.237px), memicu RenderFlex overflow yang tampil
        // sebagai garis kuning-hitam mencolok tepat di tengah stamp
        // bukti resmi. Text polos tidak pernah menyusut sendiri di
        // dalam Row - harus dibungkus Flexible agar bisa mengalah
        // (ellipsis) alih-alih overflow.
        if (stampConfig.showDate || stampConfig.showTime)
          Flexible(
            child: Text(
              '•  $timeStr',
              style: const TextStyle(
                color: Colors.white70, // Timestamp: subtext abu-abu muda
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
      ],
    );
  }

  Widget _buildGpsBadgeOnly() {
    final acc = accuracyMeters != null ? '±${accuracyMeters!.round()} m' : '±-- m';
    final gpsColor = _getGpsStatusColor(accuracyMeters ?? 100);
    return Text(
      '•  GPS $acc',
      style: TextStyle(
        color: gpsColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Mini Map Google Style dengan Pin Merah & Watermark Google (01.jpeg)
  Widget _buildMiniMapPreviewWidget({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFF1E293B),
        border: Border.all(color: Colors.white24, width: 0.8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3B4C),
            Color(0xFF1B2631),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Map texture roads / grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniMapTexturePainter(),
            ),
          ),

          // Red Google Location Pin in center
          const Icon(
            Icons.location_on,
            color: Color(0xFFEA4335), // Google Red
            size: 22,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),

          // Google logo in bottom left
          Positioned(
            left: 4,
            bottom: 3,
            child: Text(
              'Google',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // QR Code dengan Header Badge "GPS Map Camera" (01.jpeg)
  Widget _buildQrPreviewWidget({required double size}) {
    final lat = latitude ?? -4.5572;
    final lng = longitude ?? 136.8837;
    final url =
        'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
        border: Border.all(color: Colors.white54, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Mini Badge "Google Maps"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            color: const Color(0xFF0F172A),
            child: const Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Google Maps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          // QR Code Pattern
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PENTING - jangan pernah kembalikan nama wilayah/alamat REKAAN di
  // ketiga method di bawah. Ditemukan & diperbaiki: sebelumnya ketiganya
  // mengembalikan string tetap yang dibuat-buat ("Kecamatan Mimika
  // Baru...", "Cvvw+35p, Kota Mimika...", dsb) setiap kali `address`
  // null (mis. reverse geocoding gagal/timeout di lokasi sinyal lemah) -
  // dikonfirmasi NYATA lewat live-test fisik: fallback "Cvvw+35p, Kota
  // Mimika, Papua Tengah 99971, Indonesia" benar-benar tampil di layar
  // saat geocoding gagal indoor, tidak dibedakan sama sekali dari alamat
  // asli. Sejak ReverseGeocoder.reverseGeocode() diperbaiki untuk TIDAK
  // PERNAH lagi mengembalikan null (selalu alamat asli/cache/format
  // "[OFFLINE AREA]" yang jujur), cabang null di sini seharusnya tidak
  // lagi tercapai untuk capture baru - dipertahankan hanya sebagai
  // fallback jujur berbasis koordinat asli widget ini sendiri, bukan
  // nama tempat yang dikarang.
  String get _offlineCoordinateLabel {
    if (latitude == null || longitude == null) {
      return '[OFFLINE AREA] Menunggu koordinat GPS...';
    }
    return '[OFFLINE AREA] Lat: ${latitude!.toStringAsFixed(6)}, '
        'Lon: ${longitude!.toStringAsFixed(6)}';
  }

  String _getDetailedAddressLine() {
    if (address == null || address!.trim().isEmpty) {
      return _offlineCoordinateLabel;
    }
    return address!;
  }

  String _getCleanAddress() {
    if (address == null || address!.trim().isEmpty) {
      return _offlineCoordinateLabel;
    }
    final parts = address!
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return address!;
    return '${parts.take(2).join(", ")}, ${parts.skip(2).take(2).join(", ")}';
  }

  Color _getGpsStatusColor(double accuracy) {
    if (accuracy <= 10.0) return const Color(0xFF22C55E);
    if (accuracy <= 25.0) return const Color(0xFFFFC700);
    if (accuracy <= 50.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatIndonesianDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final d = dt.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? months[d.month - 1]
        : 'Agu';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} $monthName ${d.year} • $hh:$mm';
  }

  String _formatIndonesianDateOnly(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final d = dt.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? months[d.month - 1]
        : 'Agustus';
    return '${d.day} $monthName ${d.year}';
  }
}

/// Painter sederhana untuk memberikan tekstur jalan & grid pada Mini Map
class _MiniMapTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0x2238BDF8)
      ..style = PaintingStyle.fill;

    // Water area
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width * 0.4, size.height * 0.3), waterPaint);

    // Diagonal and cross roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.6, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.75), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

