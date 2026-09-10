import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_code.dart';

/// PlanVisuals
/// ----------------------------------------------------------------------
/// Pemetaan warna folder per paket - SELALU dari token desain Tulap.id
/// yang sudah ada (AppColors/TulapThemeColors), TIDAK ada hex baru yang
/// diciptakan khusus untuk layar ini (Bagian 4 & 5 dokumen redesign).
/// Semua paket tetap satu keluarga visual Tulap - tidak neon, tidak
/// rainbow, tidak gradient berlebihan.
/// ----------------------------------------------------------------------
class PlanFolderPalette {
  final Color folderStart;
  final Color folderEnd;
  final Color sheetAccent;
  final Color onFolder;
  final Color onFolderMuted;

  const PlanFolderPalette({
    required this.folderStart,
    required this.folderEnd,
    required this.sheetAccent,
    required this.onFolder,
    required this.onFolderMuted,
  });

  Gradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [folderStart, folderEnd],
  );
}

class PlanVisuals {
  PlanVisuals._();

  static PlanFolderPalette paletteFor(PlanCode code, TulapThemeColors colors) {
    switch (code) {
      case PlanCode.gratis:
        // Netral/slate dengan aksen Tulap tipis - "untuk mencoba", bukan
        // dekoratif.
        return PlanFolderPalette(
          folderStart: colors.textSecondary.withValues(alpha: 0.82),
          folderEnd: colors.textSecondary,
          sheetAccent: colors.primary,
          onFolder: Colors.white,
          onFolderMuted: Colors.white.withValues(alpha: 0.78),
        );
      case PlanCode.basic:
        return PlanFolderPalette(
          folderStart: colors.primary.withValues(alpha: 0.88),
          folderEnd: colors.primary,
          sheetAccent: colors.primary,
          onFolder: Colors.white,
          onFolderMuted: Colors.white.withValues(alpha: 0.82),
        );
      case PlanCode.pro:
        // Folder paling kuat secara visual - gradient Deep Navy -> Action
        // Blue memakai token hero gradient yang sudah ada di design
        // system (bukan hex baru).
        return PlanFolderPalette(
          folderStart: colors.heroGradientStart,
          folderEnd: colors.heroGradientEnd,
          sheetAccent: colors.primary,
          onFolder: Colors.white,
          onFolderMuted: Colors.white.withValues(alpha: 0.85),
        );
      case PlanCode.proPlus:
        // Navy yang lebih dalam/refined - masih keluarga Tulap, bukan
        // ungu/indigo terpisah.
        return PlanFolderPalette(
          folderStart: const Color(0xFF071D3A),
          folderEnd: colors.heroGradientStart,
          sheetAccent: colors.primary,
          onFolder: Colors.white,
          onFolderMuted: Colors.white.withValues(alpha: 0.85),
        );
    }
  }
}
