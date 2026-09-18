/// GpsMapCameraFormat
/// ----------------------------------------------------------------------
/// Helper format teks bersama untuk tampilan stamp gaya "GPS Map Camera"
/// (referensi: Referensi/Mobile/Camera/02.jpeg) - dipakai identik oleh tiga
/// tempat render (live viewfinder preview, hasil foto ber-watermark, & kartu
/// review foto/video) supaya ketiganya PERSIS sama, bukan tiga implementasi
/// format yang bisa saling menyimpang dari waktu ke waktu.
/// ----------------------------------------------------------------------
class GpsMapCameraFormat {
  static const _days = [
    'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu',
  ];

  /// Format persis seperti referensi: "Jumat, 18/09/2026 05:46 PM"
  /// (nama hari Indonesia, tanggal dd/MM/yyyy, jam 12-jam + AM/PM Inggris -
  /// dipertahankan AM/PM Inggris karena itu yang benar-benar tampil di
  /// aplikasi "GPS Map Camera" asli yang jadi acuan, bukan kesalahan).
  static String dayDateTime(DateTime timestamp) {
    final d = timestamp.toLocal();
    final day = _days[d.weekday % 7];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hh = hour12.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$day, $dd/$mm/$yyyy $hh:$min $ampm';
  }

  /// Format persis seperti referensi: "Lat -4.557065° Long 136.895713°"
  static String latLong(double latitude, double longitude) {
    return 'Lat ${latitude.toStringAsFixed(6)}°  Long ${longitude.toStringAsFixed(6)}°';
  }

  /// Baris judul singkat (mis. "Kecamatan Mimika Baru, Papua Tengah,
  /// Indonesia 🇮🇩") - diturunkan dari komponen alamat paling umum
  /// (kecamatan/kabupaten + provinsi) yang sudah ada di [address], BUKAN
  /// dikarang. Jika [address] kosong/offline, pakai Plus Code sebagai
  /// pengganti jujur.
  static String headline(String? address, String plusCode) {
    if (address == null || address.trim().isEmpty || address.startsWith('[OFFLINE AREA]')) {
      return plusCode.isNotEmpty ? plusCode : 'Lokasi Terverifikasi GPS';
    }

    final parts = address
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return plusCode.isNotEmpty ? plusCode : address;

    // Buang komponen murni angka (kode pos) - tidak relevan di judul singkat.
    final nonNumeric = parts.where((p) => !RegExp(r'^\d+$').hasMatch(p)).toList();
    final source = nonNumeric.isNotEmpty ? nonNumeric : parts;
    final tail = source.length <= 2 ? source : source.sublist(source.length - 2);

    var result = tail.join(', ');
    if (!result.toLowerCase().contains('indonesia')) {
      result = result.isEmpty ? 'Indonesia' : '$result, Indonesia';
    }
    return '$result 🇮🇩';
  }

  /// Alamat lengkap tanpa dipotong (dipakai untuk baris detail multi-baris
  /// di bawah judul singkat), dengan fallback jujur yang sama seperti
  /// ReverseGeocoder saat offline/kosong.
  static String fullAddress(String? address, String plusCode) {
    if (address == null || address.trim().isEmpty) {
      return plusCode.isNotEmpty ? plusCode : 'Lokasi Terverifikasi GPS';
    }
    return address;
  }
}
