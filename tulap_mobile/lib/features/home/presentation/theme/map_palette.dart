import 'package:flutter/material.dart';

/// MapPalette
/// ----------------------------------------------------------------------
/// Palet warna khusus untuk keluarga layar "Peta & Sebaran Lokasi"
/// (kartu Beranda, halaman peta penuh, halaman detail lokasi) - mengikuti
/// referensi desain "Map & Navigation App UI Kit" (hijau-teal), SENGAJA
/// terpisah dari AppColors (biru korporat) karena permintaan hanya
/// mencakup bagian peta, bukan reskin warna aplikasi secara keseluruhan.
/// ----------------------------------------------------------------------
class MapPalette {
  MapPalette._();

  /// Hijau utama - tombol aksi (Rute/Directions), pin aktif, indikator terpilih.
  static const Color accent = Color(0xFF17C673);
  static const Color accentDark = Color(0xFF0F9E5C);

  /// Teal gelap - lencana pin, search bar mengambang teks/ikon, nav pill.
  static const Color deep = Color(0xFF0E3A3A);
  static const Color deepSoft = Color(0xFF14544F);

  /// Tint hijau lembut - latar chip, highlight halus, progress bar track.
  static const Color soft = Color(0xFFE7F8EF);
  static const Color softBorder = Color(0xFFCBEEDA);

  /// Status "sedang berjalan" vs "selesai".
  static const Color statusOngoing = Color(0xFF17C673);
  static const Color statusDone = Color(0xFF64748B);

  static const Color textPrimary = Color(0xFF0B2B2B);
  static const Color textSecondary = Color(0xFF5B7876);
}
