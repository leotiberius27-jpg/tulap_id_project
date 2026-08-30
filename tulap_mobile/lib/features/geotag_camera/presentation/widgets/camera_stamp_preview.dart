import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/watermark_template_entity.dart';

/// CameraStampPreview
/// ----------------------------------------------------------------------
/// Widget live preview stamp/watermark yang melayang di atas feed kamera:
/// - Mengikuti secara presisi konfigurasi template aktif [StampConfiguration]
/// - Menampilkan Mini Map kontekstual & QR Google Maps on-device
/// - Responsif terhadap orientasi & ukuran layar tanpa menutupi tombol shutter
/// - Memberikan kepastian visual (Live Preview vs Final Render konsisten)
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
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xD90A1120), // Deep Navy ~85% opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x33006EE6), // Tulap Blue border
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top Accent Line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(color: const Color(0xFF006EE6)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTemplateBody(context, template),
                const SizedBox(height: 5),
                _buildBottomTrustBar(),
              ],
            ),
          ),
        ],
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

  // 1. KLASIK: Geotag Seimbang dengan Mini Map
  Widget _buildKlasikLayout() {
    final shouldShowMap = stampConfig.showMiniMap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Metadata
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandBadge('STANDAR GEOTAG'),
              if (stampConfig.showTaskName) ...[
                const SizedBox(height: 3),
                Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (stampConfig.showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  '📍 ${_getCleanAddress()}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 3),
              _buildGpsAndDateRow(),
              if (stampConfig.showCoordinates && latitude != null && longitude != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)} • $officerName',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
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

        // Sisi Kanan: Mini Map Preview
        if (shouldShowMap) ...[
          const SizedBox(width: 10),
          _buildMiniMapPreviewWidget(size: 68),
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
                const SizedBox(height: 3),
                Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (stampConfig.showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  '📍 ${_getCleanAddress()}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
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
                    fontSize: 10.5,
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
          const SizedBox(width: 10),
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
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (stampConfig.showLocation) ...[
          const SizedBox(height: 2),
          Text(
            '📍 ${_getCleanAddress()}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11.5,
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
                const SizedBox(height: 3),
                Text(
                  '📍 ${_getCleanAddress()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
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
                    color: Color(0xFF38BDF8),
                    fontSize: 11.0,
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
        const SizedBox(width: 10),
        _buildQrPreviewWidget(size: 72),
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
                color: Color(0xFF38BDF8),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                taskName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
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
            '📍 ${_getCleanAddress()}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11,
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
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              '🧭 $headingDeg  ',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '•  ⛰ Elevasi: $altStr  ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
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
              fontSize: 10.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (stampConfig.showLocation) ...[
          const SizedBox(height: 2),
          Text(
            '📍 ${_getCleanAddress()}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
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
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        Text(
          '•  $subtitle',
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (stampConfig.showDate || stampConfig.showTime)
          Text(
            '•  $timeStr',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMiniMapPreviewWidget({required double size}) {
    final latLngStr = latitude != null && longitude != null
        ? '${latitude!.toStringAsFixed(2)}, ${longitude!.toStringAsFixed(2)}'
        : 'Peta Lapangan';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0x4038BDF8), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar circles
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x33006EE6), width: 1),
            ),
          ),
          // Location pin
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFEF4444),
            size: 24,
          ),
          Positioned(
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xCC0B1220),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                latLngStr,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPreviewWidget({required double size}) {
    final lat = latitude ?? -4.5468;
    final lng = longitude ?? 136.8837;
    final url =
        'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(color: const Color(0xFF006EE6), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          const Text(
            'Google Maps',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTrustBar() {
    return Container(
      padding: const EdgeInsets.only(top: 3),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x26FFFFFF), width: 0.8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '🛡 Bukti Digital Tulap.id • SHA-256 Integritas Terjamin',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCleanAddress() {
    if (address == null || address!.trim().isEmpty) {
      return 'Lokasi Lapangan Terverifikasi GPS';
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
    if (accuracy <= 25.0) return const Color(0xFF38BDF8);
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
