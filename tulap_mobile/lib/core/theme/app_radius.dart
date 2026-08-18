/// AppRadius
/// ----------------------------------------------------------------------
/// Token radius sesuai Bagian 23 dokumen Product & UI/UX Specification.
/// ----------------------------------------------------------------------
class AppRadius {
  AppRadius._();

  static const double small = 8;
  static const double button = 12;
  static const double card = 16;

  /// Radius kartu besar/hero (Kartu Tugas Aktif, panel Aksi Cepat) - sesuai
  /// rentang 16-20px yang direkomendasikan Bagian 7 spesifikasi visual.
  static const double cardLarge = 20;

  /// Radius sudut bawah hero header Beranda.
  static const double hero = 28;

  /// Radius khusus sudut atas untuk Bottom Sheet
  static const double bottomSheetTop = 24;
}
