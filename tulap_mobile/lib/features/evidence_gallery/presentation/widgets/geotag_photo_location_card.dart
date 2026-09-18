import 'package:flutter/material.dart';
import '../../../../core/geo/gps_map_camera_format.dart';
import '../../../../core/imaging/geotag_watermark.dart';

/// GeotagPhotoLocationCard
/// ----------------------------------------------------------------------
/// Kartu informasi titik lokasi di bawah hasil foto ATAU video pada layar
/// review/gallery - tipis membungkus [GeotagWatermarkOverlay] (komponen
/// tunggal yang juga dipakai live di atas viewfinder kamera), supaya
/// tampilan review selalu PERSIS sama dengan live preview & foto yang
/// dibakar (lihat core/imaging/geotag_watermark.dart).
/// ----------------------------------------------------------------------
class GeotagPhotoLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final VoidCallback? onQrTap;

  const GeotagPhotoLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final qrData =
        'https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GeotagWatermarkOverlay(
        data: GeotagWatermarkData(
          latitude: latitude,
          longitude: longitude,
          addressLine1: GpsMapCameraFormat.headline(address, ''),
          addressLine2: GpsMapCameraFormat.fullAddress(address, ''),
          timestamp: timestamp,
          qrData: qrData,
        ),
        onQrTap: onQrTap,
      ),
    );
  }
}
