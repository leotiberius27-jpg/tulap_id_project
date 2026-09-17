import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// DisplaySettingsPage (Akun -> Bahasa)
/// ----------------------------------------------------------------------
/// Pengaturan dwibahasa (Bahasa Indonesia & English). Perubahan
/// diterapkan secara instan ke seluruh aplikasi.
/// ----------------------------------------------------------------------
class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = sl<LanguageController>();
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bahasa'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'BAHASA / LANGUAGE'),
              ListenableBuilder(
                listenable: languageController,
                builder: (context, _) {
                  final currentLang = languageController.currentLanguage;
                  return Container(
                    decoration: _cardDecoration(context),
                    child: Column(
                      children: [
                        // 1. Bahasa Indonesia
                        _buildLanguageOption(
                          context: context,
                          flag: AppLanguage.id.flag,
                          title: AppLanguage.id.label,
                          subtitle: AppLanguage.id.subtitle,
                          isSelected: currentLang == AppLanguage.id,
                          onTap: () => languageController.setLanguage(AppLanguage.id),
                        ),
                        Divider(height: 1, color: colors.border, indent: 56),

                        // 2. English
                        _buildLanguageOption(
                          context: context,
                          flag: AppLanguage.en.flag,
                          title: AppLanguage.en.label,
                          subtitle: AppLanguage.en.subtitle,
                          isSelected: currentLang == AppLanguage.en,
                          onTap: () => languageController.setLanguage(AppLanguage.en),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = context.tulapColors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = context.tulapColors;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      boxShadow: [
        BoxShadow(
          color: colors.shadowSoft,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: colors.border.withValues(alpha: 0.6)),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.tulapColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? colors.iconSoftBlue : colors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.small.copyWith(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: colors.primary, size: 22)
              else
                Icon(Icons.radio_button_unchecked, color: colors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
