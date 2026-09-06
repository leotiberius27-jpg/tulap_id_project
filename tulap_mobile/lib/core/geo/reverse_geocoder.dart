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

  /// Mengembalikan alamat lengkap terformat - TIDAK PERNAH `null` atau
  /// string kosong, dan TIDAK PERNAH melempar exception ke pemanggil
  /// (memenuhi kebutuhan "fetchReadableAddress" yang tangguh di area
  /// lapangan bersinyal lemah/nihil). Rantai fallback saat geocoding
  /// gagal (timeout 5 detik / tidak ada koneksi / SocketException):
  ///   Step A - pakai cache memori koordinat terdekat (< 50 meter) jika
  ///            ada, dari percobaan sukses sebelumnya di sesi yang sama.
  ///   Step B - jika tidak ada cache sama sekali, kembalikan string
  ///            jujur "[OFFLINE AREA] Koordinat: Lat: {lat}, Lon: {lng}"
  ///            - BUKAN alamat rekaan. Menampilkan alamat palsu pada
  ///            bukti resmi lebih berbahaya daripada menampilkan
  ///            koordinat mentah apa adanya.
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Cek cache memori terdekat (< 50 meter)
    if (_cachedLat != null && _cachedLng != null && _cachedAddress != null) {
      final dLat = (latitude - _cachedLat!).abs();
      final dLng = (longitude - _cachedLng!).abs();
      if (dLat < 0.00045 && dLng < 0.00045) {
        return _cachedAddress!;
      }
    }

    try {
      final placemarks = await _geo
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) {
        return _cachedAddress ?? _offlineFallback(latitude, longitude);
      }

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

      if (parts.isEmpty) {
        return _cachedAddress ?? _offlineFallback(latitude, longitude);
      }

      final formatted = parts.join(', ');
      _cachedAddress = formatted;
      _cachedLat = latitude;
      _cachedLng = longitude;
      return formatted;
    } catch (_) {
      // Offline / Timeout / SocketException apa pun: Step A lalu Step B.
      // Sengaja menangkap `Object` secara umum (bukan hanya
      // SocketException/TimeoutException) - kegagalan reverse geocoding
      // TIDAK BOLEH pernah menjatuhkan alur capture bukti di lapangan.
      return _cachedAddress ?? _offlineFallback(latitude, longitude);
    }
  }

  /// Step B dari rantai fallback - format jujur saat tidak ada koneksi
  /// DAN tidak ada cache sama sekali untuk dipakai.
  String _offlineFallback(double latitude, double longitude) {
    return '[OFFLINE AREA] Koordinat: '
        'Lat: ${latitude.toStringAsFixed(6)}, '
        'Lon: ${longitude.toStringAsFixed(6)}';
  }
}
