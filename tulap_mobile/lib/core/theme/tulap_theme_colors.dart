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

  /// Light Mode Palette (Tulap.id Classic Institutional Palette)
  static const light = TulapThemeColors(
    background: Color(0xFFF7F9FC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFEAECF0),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF667085),
    primary: Color(0xFF00529C),
    primaryHover: Color(0xFF003D75),
    action: Color(0xFF0072CE),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    successSoft: Color(0xFFE7F8F1),
    warningSoft: Color(0xFFFEF3E2),
    dangerSoft: Color(0xFFFDECEC),
    iconSoftBlue: Color(0xFFE3EEFC),
    iconSoftCyan: Color(0xFFE1F3F7),
    iconSoftTeal: Color(0xFFE0F5F0),
    iconSoftIndigo: Color(0xFFEAEAFB),
    heroGradientStart: Color(0xFF00396E),
    heroGradientEnd: Color(0xFF0064BD),
    shadowSoft: Color(0x14172033),
    inputFill: Color(0xFFFFFFFF),
    unreadCardBg: Color(0xFFF4F8FD),
  );

  /// Dark Mode Palette (Tulap.id Deep Navy Accessibility Palette)
  static const dark = TulapThemeColors(
    background: Color(0xFF0B1220), // Deep Dark Navy background
    surface: Color(0xFF111C2E), // Card Surface
    surfaceElevated: Color(0xFF16243A), // Elevated cards, popups, sheets
    cardBackground: Color(0xFF111C2E),
    border: Color(0xFF27364B), // Dark blue-gray border
    textPrimary: Color(0xFFF8FAFC), // High contrast off-white text
    textSecondary: Color(0xFFA8B3C5), // Blue-gray secondary text
    primary: Color(0xFF4DA3FF), // Vibrant Tulap Blue for dark mode readability
    primaryHover: Color(0xFF38BDF8),
    action: Color(0xFF38BDF8), // Interactive accent
    success: Color(0xFF34D399), // High contrast green
    warning: Color(0xFFFBBF24), // High contrast amber
    danger: Color(0xFFF87171), // High contrast red
    successSoft: Color(0xFF064E3B), // Dark soft green container
    warningSoft: Color(0xFF451A03), // Dark soft amber container
    dangerSoft: Color(0xFF450A0A), // Dark soft red container
    iconSoftBlue: Color(0xFF162B4D),
    iconSoftCyan: Color(0xFF0F2E3D),
    iconSoftTeal: Color(0xFF0D2E2B),
    iconSoftIndigo: Color(0xFF1E214D),
    heroGradientStart: Color(0xFF0B172B),
    heroGradientEnd: Color(0xFF142B4E),
    shadowSoft: Color(0x33000000),
    inputFill: Color(0xFF16243A),
    unreadCardBg: Color(0xFF162B4D),
  );

  static TulapThemeColors of(BuildContext context) {
    return Theme.of(context).extension<TulapThemeColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
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
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
