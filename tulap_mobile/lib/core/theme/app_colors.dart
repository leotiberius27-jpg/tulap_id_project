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

  // Brand (Light Mode - Matched to referensi-mobile-colors-A)
  static const Color primary = Color(0xFF0066FE); // Vibrant Electric Royal Blue (Dashboard button & active elements)
  static const Color primaryHover = Color(0xFF0052CC);
  static const Color action = Color(0xFF0066FE); // Tombol aksi interaktif & status aktif

  /// Gradient hero (Beranda, header layar utama)
  static const Color heroGradientStart = Color(0xFF0052D4);
  static const Color heroGradientEnd = Color(0xFF0066FE);

  /// Warna latar lingkaran ikon & kartu metrik (Soft Pastel Palette from A.png)
  static const Color iconSoftBlue = Color(0xFFEBF3FF); // Light Blue tint (Total Kendaraan)
  static const Color iconSoftCyan = Color(0xFFE6FFFA); // Light Cyan/Teal tint (Operasional)
  static const Color iconSoftTeal = Color(0xFFE6F9EE); // Light Mint Green tint (Tersedia / Sistem Aktif)
  static const Color iconSoftIndigo = Color(0xFFF3E8FF); // Light Violet/Purple tint (Dokumen)
  static const Color iconSoftAmber = Color(0xFFFFF8EB); // Light Amber/Orange tint (Dalam Perawatan)
  static const Color iconSoftRose = Color(0xFFFFEBEF); // Light Rose/Red tint (Pajak <= 30 Hari)

  /// Shadow lembut
  static const Color shadowSoft = Color(0x0F101828);

  // Status semantik (Exact matching from A.png)
  static const Color success = Color(0xFF00C263); // Vibrant Emerald Green (Tersedia / Sistem Aktif)
  static const Color warning = Color(0xFFFF9F0A); // Warm Golden Amber (Dalam Perawatan / <=60 Hari)
  static const Color danger = Color(0xFFFF3B30); // Vibrant Coral Red (Pajak <=30 Hari / Alert)

  // Layout (Light - Clean modern canvas)
  static const Color background = Color(0xFFF8FAFC); // Clean soft slate canvas
  static const Color surface = Color(0xFFFFFFFF); // Crisp pure white card
  static const Color border = Color(0xFFE2E8F0); // Subtle modern border

  // Teks (Light - High Contrast Slate Hierarchy)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 for crisp readable headings
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 for labels & metadata
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 for subtle hints

  // Warna teks kontras di atas warna semantik
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF0F172A);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Warna latar untuk chip/badge status soft
  static const Color successSoft = Color(0xFFECFDF5); // Emerald-50 soft container
  static const Color warningSoft = Color(0xFFFFFBEB); // Amber-50 soft container
  static const Color dangerSoft = Color(0xFFFEF2F2); // Red-50 soft container
  static const Color infoSoft = Color(0xFFEFF6FF); // Blue-50 soft container

  /// Helper untuk mendapatkan warna dinamis berdasarkan BuildContext
  static TulapThemeColors of(BuildContext context) => TulapThemeColors.of(context);
}

/// AppDarkColors
/// ----------------------------------------------------------------------
/// Palet warna Mode Gelap Tulap.id yang dibuat persis sama seperti
/// Mode Gelap Google Drive (Google Material Design 3 / Material You Dark Theme).
/// Menggunakan canvas #131314, container card #1E1F20, elevated #282A2C,
/// border #444746, aksen Google Blue #A8C7FA, dan teks On-Surface #E3E3E3.
/// ----------------------------------------------------------------------
class AppDarkColors {
  AppDarkColors._();

  // Brand (Google Drive M3 Dark Palette)
  static const Color primary = Color(0xFFA8C7FA); // Google Drive M3 Light Blue Accent
  static const Color primaryDeep = Color(0xFF004A77); // Google M3 Primary Container
  static const Color primaryHover = Color(0xFF8AB4F8); // Google Blue 200
  static const Color action = Color(0xFFA8C7FA); // Interactive Google Blue Accent

  // Hero Gradient (Google Drive Dark Canvas with subtle atmosphere)
  static const Color heroGradientStart = Color(0xFF131314);
  static const Color heroGradientEnd = Color(0xFF1F2E47);

  // Soft Icons (Google Drive Dark Soft Containers)
  static const Color iconSoftBlue = Color(0xFF1A273D);
  static const Color iconSoftCyan = Color(0xFF13353D);
  static const Color iconSoftTeal = Color(0xFF12382E);
  static const Color iconSoftIndigo = Color(0xFF2B234B);

  // Shadow
  static const Color shadowSoft = Color(0x66000000);

  // Status semantik (Google Material Dark Palette)
  static const Color success = Color(0xFF81C995); // Google Green 300
  static const Color warning = Color(0xFFFDD663); // Google Yellow/Amber 300
  static const Color danger = Color(0xFFF28B82); // Google Red 300

  // Layout (Google Drive Dark Surfaces)
  static const Color background = Color(0xFF131314); // Google Drive Main Canvas / Surface
  static const Color surface = Color(0xFF1E1F20); // Google Drive Card / Container Surface
  static const Color surfaceElevated = Color(0xFF282A2C); // Google Drive Elevated Sheet / Search Pill / Dialog
  static const Color border = Color(0xFF444746); // Google M3 Outline Variant

  // Teks (Google Drive On-Surface)
  static const Color textPrimary = Color(0xFFE3E3E3); // Google M3 On-Surface
  static const Color textSecondary = Color(0xFFC4C7C5); // Google M3 On-Surface-Variant
  static const Color textMuted = Color(0xFF8E918F); // Google M3 Hint / Outline

  // On Semantics
  static const Color onSuccess = Color(0xFF043818);
  static const Color onWarning = Color(0xFF382400);
  static const Color onDanger = Color(0xFF410002);
  static const Color onPrimary = Color(0xFF003258); // High contrast deep blue on light blue button

  // Status soft (Google Drive Dark Containers)
  static const Color successSoft = Color(0xFF0E3B24);
  static const Color warningSoft = Color(0xFF3E2E08);
  static const Color dangerSoft = Color(0xFF3C1414);
}
