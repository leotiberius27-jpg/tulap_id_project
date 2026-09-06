import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// GeotagPhotoLocationCard
/// ----------------------------------------------------------------------
/// Kartu informasi titik lokasi dan metadata presisi di bawah hasil foto/video
/// Sesuai referensi visual 01.jpeg (Folder Referensi/Mobile/Hasil Foto/01.jpeg):
/// - Header: TULAP.ID • NAVIGASI LAPANGAN (Teks emas #FFC700)
/// - Alamat lengkap 2-baris dengan elipsis
/// - Ikon globe biru + Koordinat presisi 6-desimal dalam warna emas (#FFC700)
/// - Akurasi GPS (GPS ±X m dalam warna emas) + Tanggal dan jam Indonesia
/// - Kotak QR Code Google Maps putih kontras tinggi di sisi kanan
/// ----------------------------------------------------------------------
class GeotagPhotoLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String? address;
  final DateTime timestamp;
  final String? tag;
  final VoidCallback? onQrTap;

  const GeotagPhotoLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.address,
    required this.timestamp,
    this.tag = 'NAVIGASI LAPANGAN',
    this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xD9000000), // Rich black, 85% opacity
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sisi Kiri: Metadata Lengkap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baris 1: TULAP.ID • NAVIGASI LAPANGAN
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TULAP.ID  ',
                      style: TextStyle(
                        color: Color(0xFFFFC700), // Golden Yellow - judul kartu
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '•  ${tag ?? "NAVIGASI LAPANGAN"}',
                      style: const TextStyle(
                        color: Color(0xFFFFC700), // Golden Yellow
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Baris 2: Alamat Lengkap
                Text(
                  _getCleanAddress(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Baris 3: 🌐 -4.556968,  136.896243
                Row(
                  children: [
                    const Text(
                      '🌐 ',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    Expanded(
                      child: Text(
                        '${latitude.toStringAsFixed(6)},  ${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white, // Koordinat: crisp white
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Baris 4: GPS ±15 m • 31 Agu 2026 • 20:34
                Row(
                  children: [
                    Text(
                      'GPS ±${accuracyMeters.round()} m',
                      style: const TextStyle(
                        color: Colors.white70, // Subtext abu-abu muda
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '  •  ${_formatIndonesianDateAndTime(timestamp)}',
                      style: const TextStyle(
                        color: Colors.white70, // Subtext abu-abu muda
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Sisi Kanan: QR Code Google Maps (01.jpeg)
          _buildQrBox(latitude, longitude),
        ],
      ),
    );
  }

  Widget _buildQrBox(double lat, double lng) {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    return GestureDetector(
      onTap: onQrTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white70, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Text(
                  'Google Maps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
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
      ),
    );
  }

  /// PENTING - jangan pernah kembalikan alamat rekaan di sini. Sebelumnya
  /// widget ini menampilkan alamat FIKTIF yang di-hardcode ("Jalan Leo
  /// Mamiri, No. 86, ...") setiap kali `address` null, pada kartu bukti
  /// audit resmi - ditemukan saat menyelaraskan widget ini dengan
  /// ReverseGeocoder.reverseGeocode() yang sekarang tidak pernah lagi
  /// mengembalikan null (selalu alamat asli, cache, atau format
  /// "[OFFLINE AREA] Koordinat: ..." yang jujur). Fallback di sini HANYA
  /// untuk foto lama yang tersimpan sebelum perbaikan tersebut ada.
  String _getCleanAddress() {
    if (address != null && address!.trim().isNotEmpty) {
      return address!;
    }
    return '[OFFLINE AREA] Koordinat: '
        'Lat: ${latitude.toStringAsFixed(6)}, '
        'Lon: ${longitude.toStringAsFixed(6)}';
  }

  String _formatIndonesianDateAndTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final local = dt.toLocal();
    final monthName = (local.month >= 1 && local.month <= 12)
        ? months[local.month - 1]
        : 'Agu';
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} $monthName ${local.year} • $hh:$mm';
  }
}
