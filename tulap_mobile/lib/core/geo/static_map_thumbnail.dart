/// Kunci Google Static Maps API opsional, dibaca dari
/// `--dart-define=GOOGLE_STATIC_MAPS_API_KEY=...` saat build (pola sama
/// dengan `_kApiBaseUrl` di injection_container.dart). Kosong secara
/// default - TIDAK ada kunci yang di-hardcode di sini karena kunci itu
/// milik akun Google Cloud pemilik proyek, bukan sesuatu yang bisa
/// dikarang.
const String _kGoogleStaticMapsApiKey = String.fromEnvironment(
  'GOOGLE_STATIC_MAPS_API_KEY',
  defaultValue: '',
);

/// StaticMapThumbnail
/// ----------------------------------------------------------------------
/// Membangun URL gambar peta statis kecil (thumbnail) untuk satu titik
/// koordinat, dipakai di watermark foto & layar detail kegiatan.
///
/// Tanpa kunci API (`GOOGLE_STATIC_MAPS_API_KEY` tidak diisi saat build),
/// memakai layanan static-map OpenStreetMap yang TIDAK butuh kunci
/// (staticmap.openstreetmap.de) - cukup untuk thumbnail kecil ber-marker,
/// walau kualitas tile-nya tidak sebaik Google. Kalau kunci Google Static
/// Maps tersedia, otomatis pakai itu untuk hasil yang lebih familiar bagi
/// pengguna Indonesia (gaya tile sama seperti Google Maps app).
/// ----------------------------------------------------------------------
class StaticMapThumbnail {
  bool get hasGoogleKey => _kGoogleStaticMapsApiKey.isNotEmpty;

  String buildUrl({
    required double latitude,
    required double longitude,
    int width = 300,
    int height = 300,
    int zoom = 16,
  }) {
    if (hasGoogleKey) {
      return 'https://maps.googleapis.com/maps/api/staticmap'
          '?center=$latitude,$longitude'
          '&zoom=$zoom'
          '&size=${width}x$height'
          '&markers=color:red%7C$latitude,$longitude'
          '&key=$_kGoogleStaticMapsApiKey';
    }

    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=$latitude,$longitude,red-pushpin';
  }

  /// URL untuk membuka lokasi di aplikasi Google Maps (tombol "Buka di
  /// Google Maps") - tidak butuh kunci API sama sekali, ini cuma deep
  /// link biasa.
  String buildGoogleMapsQueryUrl({
    required double latitude,
    required double longitude,
  }) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}
