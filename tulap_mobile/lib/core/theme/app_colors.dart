import 'package:flutter/material.dart';
import 'tulap_theme_colors.dart';

export 'app_theme_mode.dart';
export 'tulap_theme_colors.dart';

/// AppColors
/// ----------------------------------------------------------------------
/// Token warna resmi Tulap.id, mengacu langsung ke Bagian 20 & 14.1
/// dokumen Product & UI/UX Specification.
///
/// Menyediakan konstanta statis untuk Light mode (backward-compatible)
/// dan helper `AppColors.of(context)` untuk komponen yang membutuhkan
/// warna dinamis sesuai tema Light/Dark yang sedang aktif.
/// ----------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Brand (Light Mode Defaults)
  static const Color primary = Color(0xFF00529C); // Navy - brand utama
  static const Color primaryHover = Color(0xFF003D75);
  static const Color action = Color(0xFF0072CE); // Tombol aksi interaktif

  /// Gradient hero (Beranda, header layar utama)
  static const Color heroGradientStart = Color(0xFF00396E);
  static const Color heroGradientEnd = Color(0xFF0064BD);

  /// Warna latar lingkaran ikon Aksi Cepat
  static const Color iconSoftBlue = Color(0xFFE3EEFC);
  static const Color iconSoftCyan = Color(0xFFE1F3F7);
  static const Color iconSoftTeal = Color(0xFFE0F5F0);
  static const Color iconSoftIndigo = Color(0xFFEAEAFB);

  /// Shadow lembut
  static const Color shadowSoft = Color(0x14172033);

  // Status semantik
  static const Color success = Color(0xFF10B981); // Terverifikasi/Disetujui
  static const Color warning = Color(0xFFF59E0B); // Perlu perhatian
  static const Color danger = Color(0xFFEF4444); // Lokasi tidak valid/gagal

  // Layout (Light)
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAECF0);

  // Teks (Light)
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF667085);

  // Warna teks kontras di atas warna semantik
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF172033);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Warna latar untuk chip/badge status soft
  static const Color successSoft = Color(0xFFE7F8F1);
  static const Color warningSoft = Color(0xFFFEF3E2);
  static const Color dangerSoft = Color(0xFFFDECEC);

  /// Helper untuk mendapatkan warna dinamis berdasarkan BuildContext
  static TulapThemeColors of(BuildContext context) => TulapThemeColors.of(context);
}

/// AppDarkColors
/// ----------------------------------------------------------------------
/// Palet warna Mode Gelap Tulap.id berbasis Dark Navy yang elegan,
/// ramah mata untuk kondisi minim cahaya, dan menjaga identitas biru Tulap.id.
/// ----------------------------------------------------------------------
class AppDarkColors {
  AppDarkColors._();

  // Brand (Dark Mode)
  static const Color primary = Color(0xFF4DA3FF); // Vibrant accessible blue
  static const Color primaryDeep = Color(0xFF00529C);
  static const Color primaryHover = Color(0xFF38BDF8);
  static const Color action = Color(0xFF38BDF8);

  // Hero Gradient (Dark Navy Tones)
  static const Color heroGradientStart = Color(0xFF0B172B);
  static const Color heroGradientEnd = Color(0xFF142B4E);

  // Soft Icons (Dark)
  static const Color iconSoftBlue = Color(0xFF162B4D);
  static const Color iconSoftCyan = Color(0xFF0F2E3D);
  static const Color iconSoftTeal = Color(0xFF0D2E2B);
  static const Color iconSoftIndigo = Color(0xFF1E214D);

  // Shadow
  static const Color shadowSoft = Color(0x33000000);

  // Status semantik (High-contrast for dark)
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  // Layout (Dark Navy Hierarchy)
  static const Color background = Color(0xFF0B1220); // Very dark navy
  static const Color surface = Color(0xFF111C2E); // Card surface
  static const Color surfaceElevated = Color(0xFF16243A); // Elevated sheet/dialog
  static const Color border = Color(0xFF27364B); // Dark blue-gray border

  // Teks (Dark)
  static const Color textPrimary = Color(0xFFF8FAFC); // Near white
  static const Color textSecondary = Color(0xFFA8B3C5); // Blue-gray

  // On Semantics
  static const Color onSuccess = Color(0xFF064E3B);
  static const Color onWarning = Color(0xFF451A03);
  static const Color onDanger = Color(0xFF450A0A);
  static const Color onPrimary = Color(0xFF0B1220);

  // Status soft (Dark)
  static const Color successSoft = Color(0xFF064E3B);
  static const Color warningSoft = Color(0xFF451A03);
  static const Color dangerSoft = Color(0xFF450A0A);
}
