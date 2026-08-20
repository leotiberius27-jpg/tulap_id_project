import 'package:open_location_code/open_location_code.dart' as olc;

/// PlusCodeGenerator
/// ----------------------------------------------------------------------
/// Menghasilkan Open Location Code (Google "Plus Code") dari koordinat,
/// mis. `6P58RR28+2M`. Dipakai untuk watermark bukti foto & layar detail
/// kegiatan - Plus Code bisa langsung dicari di Google Maps tanpa perlu
/// alamat jalan yang eksak, berguna untuk lokasi lapangan terpencil.
///
/// Memakai package `open_location_code` (bukan implementasi manual) -
/// encoding OLC punya banyak konstanta presisi yang mudah salah ketik;
/// hasil package ini sudah diverifikasi round-trip encode->decode
/// terhadap titik referensi sebelum dipakai di sini.
/// ----------------------------------------------------------------------
class PlusCodeGenerator {
  /// Menghasilkan Plus Code lengkap (10 digit + separator, presisi
  /// terbaik ~13m x 13m) dari [latitude]/[longitude].
  String generate({required double latitude, required double longitude}) {
    return olc.PlusCode.encode(olc.LatLng(latitude, longitude)).toString();
  }
}
