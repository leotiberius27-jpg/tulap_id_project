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
  final Geocoding _geocoding = Geocoding();

  /// Mengembalikan alamat lengkap terformat, atau `null` jika geocoder
  /// tidak menemukan hasil apa pun untuk koordinat ini (mis. lokasi
  /// terpencil tanpa data peta) - caller tetap menyimpan lat/long
  /// mentah sebagai fallback, address murni pelengkap.
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks =
        await _geocoding.placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final parts = <String>[
      if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare!,
      if ((p.subThoroughfare ?? '').isNotEmpty) 'No. ${p.subThoroughfare}',
      if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
      if ((p.locality ?? '').isNotEmpty) p.locality!,
      if ((p.subAdministrativeArea ?? '').isNotEmpty) p.subAdministrativeArea!,
      if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
      if ((p.postalCode ?? '').isNotEmpty) p.postalCode!,
    ];

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
