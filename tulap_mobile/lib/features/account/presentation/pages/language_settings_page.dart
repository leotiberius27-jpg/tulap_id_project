import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// LanguageSettingsPage
/// ----------------------------------------------------------------------
/// Halaman Pengaturan Bahasa Tulap.id (Bahasa Indonesia & English).
/// - Pilihan kartu visual dwibahasa dengan bendera & deskripsi
/// - Ganti bahasa secara instan dan tersimpan aman di secure storage
/// ----------------------------------------------------------------------
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = sl<LanguageController>();
    final colors = context.tulapColors;
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        final currentLanguage = languageController.currentLanguage;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              l10n.language,
              style: AppTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.lg,
            ),
            children: [
              // Header description
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.isEnglish
                            ? 'Select your preferred application language. All text will be updated immediately.'
                            : 'Pilih bahasa aplikasi yang Anda inginkan. Seluruh teks akan langsung diperbarui.',
                        style: AppTypography.small.copyWith(
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  l10n.selectLanguage.toUpperCase(),
                  style: AppTypography.small.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              // Language Option 1: Bahasa Indonesia
              _buildLanguageCard(
                context: context,
                language: AppLanguage.id,
                isSelected: currentLanguage == AppLanguage.id,
                onTap: () => languageController.setLanguage(AppLanguage.id),
              ),
              const SizedBox(height: AppSpacing.md),

              // Language Option 2: English
              _buildLanguageCard(
                context: context,
                language: AppLanguage.en,
                isSelected: currentLanguage == AppLanguage.en,
                onTap: () => languageController.setLanguage(AppLanguage.en),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required AppLanguage language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.tulapColors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: language.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Flag emoji circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.1)
                      : colors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Language Name & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.label,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.subtitle,
                      style: AppTypography.small.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Radio / Check icon
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                    width: 2.0,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
