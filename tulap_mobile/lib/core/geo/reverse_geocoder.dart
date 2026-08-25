import 'package:geocoding/geocoding.dart';

/// ReverseGeocoder
/// ----------------------------------------------------------------------
/// Mengonversi koordinat (lat, long) menjadi alamat lengkap yang bisa
/// dibaca manusia, dipakai untuk watermark bukti foto & layar detail
/// kegiatan. Memakai package `geocoding` (native Geocoder Android/iOS,
/// via Google Play Services di Android - TIDAK butuh API key terpisah).
///
/// CATATAN JUJUR: RT/RW tidak tersedia dari sumber data ini - Geocoder
/// Android/Google tidak memetakan unit RT/RW Indonesia sama sekali,
/// hanya sampai level kelurahan/kecamatan/kota. String alamat di bawah
/// disusun HANYA dari komponen yang benar-benar dikembalikan geocoder -
/// tidak ada bagian yang direkayasa saat komponen itu kosong.
/// ----------------------------------------------------------------------
class ReverseGeocoder {
  Geocoding? _geocoding;
  Geocoding get _geo => _geocoding ??= Geocoding();

  String? _cachedAddress;
  double? _cachedLat;
  double? _cachedLng;

  /// Mengembalikan alamat lengkap terformat, atau `null` jika geocoder
  /// tidak menemukan hasil apa pun untuk koordinat ini (mis. lokasi
  /// terpencil tanpa data peta) - caller tetap menyimpan lat/long
  /// mentah sebagai fallback, address murni pelengkap.
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Cek cache memori terdekat (< 50 meter)
    if (_cachedLat != null && _cachedLng != null && _cachedAddress != null) {
      final dLat = (latitude - _cachedLat!).abs();
      final dLng = (longitude - _cachedLng!).abs();
      if (dLat < 0.00045 && dLng < 0.00045) {
        return _cachedAddress;
      }
    }

    try {
      final placemarks = await _geo
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 4));

      if (placemarks.isEmpty) return _cachedAddress;

      final p = placemarks.first;
      final parts = <String>[
        if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare!,
        if ((p.subThoroughfare ?? '').isNotEmpty) 'No. ${p.subThoroughfare}',
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
        if ((p.locality ?? '').isNotEmpty) p.locality!,
        if ((p.subAdministrativeArea ?? '').isNotEmpty)
          p.subAdministrativeArea!,
        if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
        if ((p.postalCode ?? '').isNotEmpty) p.postalCode!,
      ];

      if (parts.isEmpty) return _cachedAddress;

      final formatted = parts.join(', ');
      _cachedAddress = formatted;
      _cachedLat = latitude;
      _cachedLng = longitude;
      return formatted;
    } catch (_) {
      // Offline / Timeout: kembalikan cache jika ada, atau null
      return _cachedAddress;
    }
  }
}
