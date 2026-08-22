import 'package:flutter/animation.dart';

/// AppMotion
/// ----------------------------------------------------------------------
/// Token durasi & easing terpusat agar Tulap.id terasa "hidup" tapi tetap
/// tenang - microinteraction singkat, tidak ada transisi dekoratif >350ms.
/// ----------------------------------------------------------------------
class AppMotion {
  AppMotion._();

  /// Microinteraction: ripple/scale tombol, ikon aksi cepat.
  static const Duration micro = Duration(milliseconds: 150);

  /// Perubahan state kecil: chip status, badge, teks yang berganti.
  static const Duration stateChange = Duration(milliseconds: 220);

  /// Kartu: progress bar checklist/tugas, munculnya kartu baru.
  static const Duration card = Duration(milliseconds: 260);

  /// Bottom sheet (Review OCR, dsb).
  static const Duration sheet = Duration(milliseconds: 300);

  /// Transisi antar layar/tab.
  static const Duration screen = Duration(milliseconds: 260);

  /// Entrance sekali-jalan: kartu/headline muncul pertama kali di layar.
  static const Duration entrance = Duration(milliseconds: 550);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutCirc;
}
