import 'package:flutter/material.dart';

/// TulapThemeColors
/// ----------------------------------------------------------------------
/// Token warna tematik Tulap.id yang terpasang sebagai ThemeExtension.
/// Menyediakan akses semantic token untuk Light dan Dark themes
/// secara konsisten di seluruh widget tree.
/// ----------------------------------------------------------------------
@immutable
class TulapThemeColors extends ThemeExtension<TulapThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color cardBackground;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryHover;
  final Color action;
  final Color success;
  final Color warning;
  final Color danger;
  final Color successSoft;
  final Color warningSoft;
  final Color dangerSoft;
  final Color iconSoftBlue;
  final Color iconSoftCyan;
  final Color iconSoftTeal;
  final Color iconSoftIndigo;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color shadowSoft;
  final Color inputFill;
  final Color unreadCardBg;

  const TulapThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.cardBackground,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryHover,
    required this.action,
    required this.success,
    required this.warning,
    required this.danger,
    required this.successSoft,
    required this.warningSoft,
    required this.dangerSoft,
    required this.iconSoftBlue,
    required this.iconSoftCyan,
    required this.iconSoftTeal,
    required this.iconSoftIndigo,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.shadowSoft,
    required this.inputFill,
    required this.unreadCardBg,
  });

  /// Light Mode Palette
  static const light = TulapThemeColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    primary: Color(0xFF0057B8),
    primaryHover: Color(0xFF00478F),
    action: Color(0xFF0057B8),
    success: Color(0xFF29C763),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    successSoft: Color(0xFFF0FDF4),
    warningSoft: Color(0xFFFFF7ED),
    dangerSoft: Color(0xFFFEF2F2),
    iconSoftBlue: Color(0xFFEFF6FF),
    iconSoftCyan: Color(0xFFE6FFFA),
    iconSoftTeal: Color(0xFFF0FDF4),
    iconSoftIndigo: Color(0xFFE9D5FF),
    heroGradientStart: Color(0xFF003D82),
    heroGradientEnd: Color(0xFF0057B8),
    shadowSoft: Color(0x0F101828),
    inputFill: Color(0xFFFFFFFF),
    unreadCardBg: Color(0xFFEFF6FF),
  );

  static TulapThemeColors of(BuildContext context) {
    return Theme.of(context).extension<TulapThemeColors>() ?? light;
  }

  @override
  TulapThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? cardBackground,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? primaryHover,
    Color? action,
    Color? success,
    Color? warning,
    Color? danger,
    Color? successSoft,
    Color? warningSoft,
    Color? dangerSoft,
    Color? iconSoftBlue,
    Color? iconSoftCyan,
    Color? iconSoftTeal,
    Color? iconSoftIndigo,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? shadowSoft,
    Color? inputFill,
    Color? unreadCardBg,
  }) {
    return TulapThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      cardBackground: cardBackground ?? this.cardBackground,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      action: action ?? this.action,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      iconSoftBlue: iconSoftBlue ?? this.iconSoftBlue,
      iconSoftCyan: iconSoftCyan ?? this.iconSoftCyan,
      iconSoftTeal: iconSoftTeal ?? this.iconSoftTeal,
      iconSoftIndigo: iconSoftIndigo ?? this.iconSoftIndigo,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      inputFill: inputFill ?? this.inputFill,
      unreadCardBg: unreadCardBg ?? this.unreadCardBg,
    );
  }

  @override
  TulapThemeColors lerp(ThemeExtension<TulapThemeColors>? other, double t) {
    if (other is! TulapThemeColors) return this;
    return TulapThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      action: Color.lerp(action, other.action, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      iconSoftBlue: Color.lerp(iconSoftBlue, other.iconSoftBlue, t)!,
      iconSoftCyan: Color.lerp(iconSoftCyan, other.iconSoftCyan, t)!,
      iconSoftTeal: Color.lerp(iconSoftTeal, other.iconSoftTeal, t)!,
      iconSoftIndigo: Color.lerp(iconSoftIndigo, other.iconSoftIndigo, t)!,
      heroGradientStart: Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      unreadCardBg: Color.lerp(unreadCardBg, other.unreadCardBg, t)!,
    );
  }
}

/// Extension helper on BuildContext
extension TulapThemeContextExtension on BuildContext {
  TulapThemeColors get tulapColors => TulapThemeColors.of(this);
}
