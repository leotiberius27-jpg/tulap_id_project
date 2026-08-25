import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTypography
/// ----------------------------------------------------------------------
/// Skala tipografi sesuai Bagian 21 dokumen spesifikasi. Font utama
/// Plus Jakarta Sans, dengan Inter sebagai fallback jika font family
/// belum termuat.
///
/// Mendukung Light dan Dark themes dengan kontras yang teruji.
/// ----------------------------------------------------------------------
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'PlusJakartaSans';
  static const String fontFamilyFallback = 'Inter';

  // --- LIGHT STYLES ---
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
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle nominalDisplay = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.3,
  );

  // --- DARK STYLES ---
  static const TextStyle displayDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle pageTitleDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle sectionTitleDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppDarkColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppDarkColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondaryDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppDarkColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle smallDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppDarkColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle nominalDisplayDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle sectionLabelDark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppDarkColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.3,
  );

  // --- BRAND & HERO STYLES (Fixed on Blue/Dark Gradient) ---
  static const TextStyle brandTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.6,
  );

  static const TextStyle heroGreeting = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    height: 1.3,
  );

  static const TextStyle heroName = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamilyFallback],
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    height: 1.4,
  );

  /// TextTheme Generator for ThemeData
  static TextTheme lightTextTheme = const TextTheme(
    displayLarge: display,
    headlineMedium: pageTitle,
    titleMedium: sectionTitle,
    bodyLarge: body,
    bodyMedium: bodySecondary,
    labelMedium: small,
  );

  static TextTheme darkTextTheme = const TextTheme(
    displayLarge: displayDark,
    headlineMedium: pageTitleDark,
    titleMedium: sectionTitleDark,
    bodyLarge: bodyDark,
    bodyMedium: bodySecondaryDark,
    labelMedium: smallDark,
  );
}
