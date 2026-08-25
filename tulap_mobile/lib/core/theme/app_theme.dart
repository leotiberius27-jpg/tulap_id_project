import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_theme_mode.dart';
import 'app_typography.dart';
import 'tulap_theme_colors.dart';

export 'app_colors.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_theme_mode.dart';
export 'app_typography.dart';
export 'tulap_theme_colors.dart';

/// AppTheme
/// ----------------------------------------------------------------------
/// Titik pemasangan seluruh token desain ke dalam ThemeData Flutter.
/// Mendukung Light Theme dan Dark Theme (Dark Navy Tulap.id).
/// ----------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  /// Light Theme (Standar Lapangan Tulap.id)
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
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,
      extensions: const [TulapThemeColors.light],

      textTheme: AppTypography.lightTextTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
      ),

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
          minimumSize: const Size(44, 44),
          textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

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

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
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

  /// Dark Theme (Dark Navy Kontras Tinggi Tulap.id)
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppDarkColors.primary,
      secondary: AppDarkColors.action,
      error: AppDarkColors.danger,
      surface: AppDarkColors.surface,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDarkColors.background,
      fontFamily: AppTypography.fontFamily,
      extensions: const [TulapThemeColors.dark],

      textTheme: AppTypography.darkTextTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppDarkColors.surface,
        foregroundColor: AppDarkColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitleDark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: AppDarkColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.bodyDark.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDarkColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppDarkColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.bodyDark.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDarkColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: AppTypography.bodyDark.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppDarkColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppDarkColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppDarkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppDarkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppDarkColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppDarkColors.danger),
        ),
        hintStyle: AppTypography.bodySecondaryDark,
        labelStyle: AppTypography.bodySecondaryDark,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDarkColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppDarkColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppDarkColors.surfaceElevated,
        labelStyle: AppTypography.smallDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        side: const BorderSide(color: AppDarkColors.border),
      ),

      dividerTheme: const DividerThemeData(
        color: AppDarkColors.border,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDarkColors.surface,
        selectedItemColor: AppDarkColors.primary,
        unselectedItemColor: AppDarkColors.textSecondary,
        selectedLabelStyle: AppTypography.smallDark,
        unselectedLabelStyle: AppTypography.smallDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

/// StatusColor
/// ----------------------------------------------------------------------
/// Helper untuk memetakan status semantik ke pasangan warna latar & teks.
/// ----------------------------------------------------------------------
enum AppStatusTone { success, warning, danger, neutral }

class StatusColor {
  StatusColor._();

  static Color foreground(BuildContext context, AppStatusTone tone) {
    final colors = TulapThemeColors.of(context);
    switch (tone) {
      case AppStatusTone.success:
        return colors.success;
      case AppStatusTone.warning:
        return colors.warning;
      case AppStatusTone.danger:
        return colors.danger;
      case AppStatusTone.neutral:
        return colors.textSecondary;
    }
  }

  static Color background(BuildContext context, AppStatusTone tone) {
    final colors = TulapThemeColors.of(context);
    switch (tone) {
      case AppStatusTone.success:
        return colors.successSoft;
      case AppStatusTone.warning:
        return colors.warningSoft;
      case AppStatusTone.danger:
        return colors.dangerSoft;
      case AppStatusTone.neutral:
        return colors.background;
    }
  }
}
