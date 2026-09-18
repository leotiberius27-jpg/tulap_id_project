import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/geo/gps_map_camera_format.dart';
import '../../../../core/widgets/real_mini_map_preview.dart';

/// GeotagPhotoLocationCard
/// ----------------------------------------------------------------------
/// Kartu informasi titik lokasi dan metadata presisi di bawah hasil foto
/// ATAU video, identik referensi Referensi/Mobile/Camera/02.jpeg:
/// - Peta lokasi NYATA (Google/OSM static map) di sisi kiri
/// - Judul wilayah singkat + bendera 🇮🇩, alamat lengkap, koordinat
///   "Lat X° Long Y°", & tanggal/jam bergaya "Hari, dd/MM/yyyy hh:mm AM/PM"
/// - Badge "GPS Map Camera" + kotak QR Google Maps putih polos di kanan
/// ----------------------------------------------------------------------
class GeotagPhotoLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String? address;
  final DateTime timestamp;
  final VoidCallback? onQrTap;

  const GeotagPhotoLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.address,
    required this.timestamp,
    this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sisi Kiri: Peta Lokasi Nyata
          RealMiniMapPreview(
            latitude: latitude,
            longitude: longitude,
            size: 80,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 10),

          // Tengah: Judul Wilayah, Alamat, Koordinat, Tanggal & Jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  GpsMapCameraFormat.headline(address, ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  GpsMapCameraFormat.fullAddress(address, ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  GpsMapCameraFormat.latLong(latitude, longitude),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  GpsMapCameraFormat.dayDateTime(timestamp),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Sisi Kanan: Badge "GPS Map Camera" + QR Google Maps
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🛰 GPS Map Camera',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _buildQrBox(latitude, longitude),
            ],
          ),
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
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
            ),
          ],
        ),
        child: QrImageView(
          data: url,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
