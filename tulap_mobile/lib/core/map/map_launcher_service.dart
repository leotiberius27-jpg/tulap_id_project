import 'package:url_launcher/url_launcher.dart';

/// MapLauncherService
/// ----------------------------------------------------------------------
/// Membuka lokasi bukti kegiatan di Google Maps menggunakan koordinat
/// tersimpan dari Evidence record.
/// ----------------------------------------------------------------------
class MapLauncherService {
  String buildGoogleMapsUrl({
    required double latitude,
    required double longitude,
  }) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      buildGoogleMapsUrl(latitude: latitude, longitude: longitude),
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (_) {
      return false;
    }
  }
}
