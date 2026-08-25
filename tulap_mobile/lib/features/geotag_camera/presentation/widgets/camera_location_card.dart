import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// CameraLocationCard
/// ----------------------------------------------------------------------
/// Panel semi-transparan (Dark Frosted Glass) di bagian bawah preview
/// kamera live, menampilkan konteks tugas & informasi geolokasi real-time:
/// - Judul Tugas / Nama Aktivitas
/// - 📍 Alamat hasil reverse geocoding (atau fallback status)
/// - Koordinat Latitude & Longitude presisi 6 desimal
/// - Akurasi GPS (±X meter)
/// - Jam & Tanggal live (WIB / WITA / WIT)
/// ----------------------------------------------------------------------
class CameraLocationCard extends StatelessWidget {
  final String taskName;
  final String officerName;
  final String agencyName;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? address;
  final DateTime currentTime;

  const CameraLocationCard({
    super.key,
    required this.taskName,
    required this.officerName,
    required this.agencyName,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.address,
    required this.currentTime,
  });

  String _formatDateTime(DateTime time) {
    const months = [
      'Jan',
      'Feb',
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
    final day = time.day;
    final month = months[time.month - 1];
    final year = time.year;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');

    // Tentukan zona waktu lokal Indonesia berdasarkan offset
    final offsetHours = time.timeZoneOffset.inHours;
    String tz = 'WIB';
    if (offsetHours >= 9) {
      tz = 'WIT';
    } else if (offsetHours == 8) {
      tz = 'WITA';
    }

    return '$day $month $year • $hh:$mm:$ss $tz';
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;
    final coordsText = hasCoords
        ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
        : 'Mengambil koordinat GPS...';

    final accText = accuracyMeters != null
        ? 'Akurasi ±${accuracyMeters!.round()} meter'
        : 'Menghitung akurasi...';

    final addressText = address != null && address!.isNotEmpty
        ? address!
        : (hasCoords ? 'Mencari alamat lokasi...' : 'Lokasi belum tersedia');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xCC0B132B), // Dark Navy Glass ~80% opacity
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Baris Judul Tugas & Instansi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 3.5,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF006EE6), // Tulap Blue Accent
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName.isNotEmpty
                          ? taskName
                          : 'Dokumentasi Tugas Lapangan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$officerName • $agencyName',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 8),

          // 2. Baris Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 15,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 3. Baris Koordinat & Akurasi + Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordsText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accText,
                      style: TextStyle(
                        color: (accuracyMeters != null && accuracyMeters! <= 15)
                            ? const Color(0xFF4ADE80) // Green
                            : const Color(0xFFFBBF24), // Amber
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDateTime(currentTime),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
