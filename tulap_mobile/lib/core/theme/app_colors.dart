import 'package:flutter/material.dart';
import 'tulap_theme_colors.dart';

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

  // Brand (Light Mode - uji coba palet dari Referensi/Collors/01-05.png)
  static const Color primary = Color(0xFF0057B8); // Corporate navy blue (Dashboard button & active elements)
  static const Color primaryHover = Color(0xFF00478F);
  static const Color action = Color(0xFF0057B8); // Tombol aksi interaktif & status aktif

  /// Gradient hero (Beranda, header layar utama)
  static const Color heroGradientStart = Color(0xFF003D82);
  static const Color heroGradientEnd = Color(0xFF0057B8);

  /// Warna latar lingkaran ikon & kartu metrik (Soft Pastel Palette - uji coba)
  static const Color iconSoftBlue = Color(0xFFEFF6FF); // Light Blue tint (Total Kendaraan)
  static const Color iconSoftCyan = Color(0xFFE6FFFA); // Light Cyan/Teal tint (Operasional)
  static const Color iconSoftTeal = Color(0xFFF0FDF4); // Light Mint Green tint (Tersedia / Sistem Aktif)
  static const Color iconSoftIndigo = Color(0xFFE9D5FF); // Light Violet/Purple tint (Dokumen)
  static const Color iconSoftAmber = Color(0xFFFFF7ED); // Light Amber/Orange tint (Dalam Perawatan)
  static const Color iconSoftRose = Color(0xFFFEF2F2); // Light Rose/Red tint (Pajak <= 30 Hari)

  /// Shadow lembut
  static const Color shadowSoft = Color(0x0F101828);

  // Status semantik (uji coba palet dari Referensi/Collors/01-05.png)
  static const Color success = Color(0xFF29C763); // Emerald Green (Tersedia / Sistem Aktif)
  static const Color warning = Color(0xFFF59E0B); // Warm Amber (Dalam Perawatan / <=60 Hari)
  static const Color danger = Color(0xFFDC2626); // Red (Pajak <=30 Hari / Alert)

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
  static const Color successSoft = Color(0xFFF0FDF4); // Green-50 soft container
  static const Color warningSoft = Color(0xFFFFF7ED); // Orange-50 soft container
  static const Color dangerSoft = Color(0xFFFEF2F2); // Red-50 soft container
  static const Color infoSoft = Color(0xFFEFF6FF); // Blue-50 soft container

  /// Helper untuk mendapatkan warna dinamis berdasarkan BuildContext
  static TulapThemeColors of(BuildContext context) => TulapThemeColors.of(context);
}
