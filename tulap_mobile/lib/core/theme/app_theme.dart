import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_radius.dart';
export 'app_typography.dart';

/// AppTheme
/// ----------------------------------------------------------------------
/// Titik pemasangan seluruh token desain ke dalam ThemeData Flutter.
/// Dipakai di `MaterialApp(theme: AppTheme.light)`.
///
/// Semua nilai warna/ukuran di sini WAJIB mengacu ke AppColors,
/// AppSpacing, AppRadius, AppTypography - tidak boleh ada angka/hex
/// "liar" ditulis ulang di file ini.
/// ----------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.action,
      error: AppColors.danger,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,

      // Tipografi terpusat mengikuti skala di Bagian 21
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineMedium: AppTypography.pageTitle,
        titleMedium: AppTypography.sectionTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySecondary,
        labelMedium: AppTypography.small,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
      ),

      // Tombol Primary - height 52px, radius 12px sesuai Bagian 24.
      // Minimum touch target 44x44 otomatis terpenuhi karena tinggi 52px.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.action,
          minimumSize: const Size(44, 44), // Minimum touch target
          textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Kartu (Task Card, Receipt Card, dsb) - radius 16px sesuai Bagian 23
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.action, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: AppTypography.bodySecondary,
        labelStyle: AppTypography.bodySecondary,
      ),

      // Bottom Sheet (Review OCR, Konfirmasi, dsb) - radius atas 24px
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        labelStyle: AppTypography.small,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.small,
        unselectedLabelStyle: AppTypography.small,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

/// StatusColor
/// ----------------------------------------------------------------------
/// Helper untuk memetakan status semantik (Task/Sync/GPS/Receipt - lihat
/// Bagian 25) ke pasangan warna & warna latar soft-nya. Dipakai oleh
/// widget StatusBadge/Chip agar mapping status->warna konsisten di
/// seluruh aplikasi dan tidak ditulis ulang berkali-kali di tiap layar.
/// ----------------------------------------------------------------------
enum AppStatusTone { success, warning, danger, neutral }

class StatusColor {
  StatusColor._();

  static Color foreground(AppStatusTone tone) {
    switch (tone) {
      case AppStatusTone.success:
        return AppColors.success;
      case AppStatusTone.warning:
        return AppColors.warning;
      case AppStatusTone.danger:
        return AppColors.danger;
      case AppStatusTone.neutral:
        return AppColors.textSecondary;
    }
  }

  static Color background(AppStatusTone tone) {
    switch (tone) {
      case AppStatusTone.success:
        return AppColors.successSoft;
      case AppStatusTone.warning:
        return AppColors.warningSoft;
      case AppStatusTone.danger:
        return AppColors.dangerSoft;
      case AppStatusTone.neutral:
        return AppColors.background;
    }
  }
}
