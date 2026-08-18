import 'package:flutter/material.dart';

/// AppColors
/// ----------------------------------------------------------------------
/// Token warna resmi Tulap.id, mengacu langsung ke Bagian 20 & 14.1
/// dokumen Product & UI/UX Specification. JANGAN pernah pakai kode
/// hex langsung di widget — selalu rujuk lewat class ini agar tema
/// tetap satu sumber kebenaran (single source of truth).
/// ----------------------------------------------------------------------
class AppColors {
  AppColors._(); // Mencegah instansiasi, class ini hanya wadah konstanta

  // Brand
  static const Color primary = Color(0xFF00529C); // Navy - brand utama
  static const Color primaryHover = Color(0xFF003D75);
  static const Color action = Color(0xFF0072CE); // Tombol aksi interaktif

  /// Gradient hero (Beranda, header layar utama) - biru dalam ke biru
  /// institusional yang lebih cerah, dipakai sangat subtle (lihat Bagian 5
  /// spesifikasi visual: "Deep/medium blue -> brighter institutional blue").
  static const Color heroGradientStart = Color(0xFF00396E);
  static const Color heroGradientEnd = Color(0xFF0064BD);

  /// Warna latar lingkaran ikon Aksi Cepat - variasi biru/cyan/teal yang
  /// tetap harmonis, tidak berubah jadi pelangi (Bagian 10).
  static const Color iconSoftBlue = Color(0xFFE3EEFC);
  static const Color iconSoftCyan = Color(0xFFE1F3F7);
  static const Color iconSoftTeal = Color(0xFFE0F5F0);
  static const Color iconSoftIndigo = Color(0xFFEAEAFB);

  /// Warna shadow lembut pengganti border tebal pada kartu (Bagian 7).
  static const Color shadowSoft = Color(0x14172033);

  // Status semantik
  static const Color success = Color(0xFF10B981); // Terverifikasi/Disetujui
  static const Color warning = Color(0xFFF59E0B); // Perlu perhatian
  static const Color danger = Color(0xFFEF4444); // Lokasi tidak valid/gagal

  // Layout
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAECF0);

  // Teks
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF667085);

  // Warna teks kontras di atas warna semantik (mis. teks putih di badge hijau)
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF172033);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Warna latar untuk chip/badge status (versi soft/tint dari warna utama)
  static const Color successSoft = Color(0xFFE7F8F1);
  static const Color warningSoft = Color(0xFFFEF3E2);
  static const Color dangerSoft = Color(0xFFFDECEC);
}
