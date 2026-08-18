import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTypography
/// ----------------------------------------------------------------------
/// Skala tipografi sesuai Bagian 21 dokumen spesifikasi. Font utama
/// Plus Jakarta Sans, dengan Inter sebagai fallback jika font family
/// belum termuat (mis. saat pertama kali install).
///
/// PENTING: Body text mobile TIDAK BOLEH di bawah 14px — ini adalah
/// syarat aksesibilitas untuk pegawai senior (lihat Bagian 26).
/// ----------------------------------------------------------------------
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'PlusJakartaSans';
  static const String fontFamilyFallback = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 18,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 14, // Minimum body text mobile - jangan diperkecil lagi
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Style khusus untuk nominal besar (mis. hasil OCR nota, ringkasan
  /// keuangan) - sesuai kebutuhan "Large number display" di Bagian 26.
  static const TextStyle nominalDisplay = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Label section kecil (mis. "Aksi Cepat", "Status Data", "TUGAS AKTIF")
  /// - semibold, letter-spacing tipis, jangan sebesar sectionTitle agar
  /// hierarki di antara label section dan judul kartu tetap terasa.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.3,
  );

  /// Wordmark brand di hero header (mis. "TULAP.ID").
  static const TextStyle brandTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.6,
  );

  /// Sapaan di hero header (mis. "Selamat Pagi,") - lebih ringan dari nama.
  static const TextStyle heroGreeting = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    height: 1.3,
  );

  /// Nama pegawai di hero header - titik fokus utama hero.
  static const TextStyle heroName = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );

  /// Instansi di hero header - muted, lebih kecil dari nama.
  static const TextStyle heroSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    height: 1.4,
  );
}
