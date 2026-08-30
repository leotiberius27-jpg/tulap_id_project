import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';

/// DisplaySettingsPage (Akun -> Tampilan)
/// ----------------------------------------------------------------------
/// Pengaturan tema tampilan global (Sistem, Terang, Gelap) dan
/// pengaturan dwibahasa (Bahasa Indonesia & English).
/// Perubahan diterapkan secara instan ke seluruh aplikasi.
/// ----------------------------------------------------------------------
class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    final languageController = sl<LanguageController>();
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tampilan'),
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
        child: ListenableBuilder(
          listenable: themeController,
          builder: (context, _) {
            final currentMode = themeController.appThemeMode;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'TEMA APLIKASI'),
                  Container(
                    decoration: _cardDecoration(context),
                    child: Column(
                      children: [
                        // 1. Ikuti Sistem
                        _buildThemeOption(
                          context: context,
                          icon: Icons.brightness_auto_rounded,
                          title: AppThemeMode.system.label,
                          subtitle: AppThemeMode.system.subtitle,
                          isSelected: currentMode == AppThemeMode.system,
                          onTap: () => themeController.setThemeMode(AppThemeMode.system),
                        ),
                        Divider(height: 1, color: colors.border, indent: 56),

                        // 2. Mode Terang
                        _buildThemeOption(
                          context: context,
                          icon: Icons.light_mode_rounded,
                          title: AppThemeMode.light.label,
                          subtitle: AppThemeMode.light.subtitle,
                          isSelected: currentMode == AppThemeMode.light,
                          onTap: () => themeController.setThemeMode(AppThemeMode.light),
                        ),
                        Divider(height: 1, color: colors.border, indent: 56),

                        // 3. Mode Gelap
                        _buildThemeOption(
                          context: context,
                          icon: Icons.dark_mode_rounded,
                          title: AppThemeMode.dark.label,
                          subtitle: AppThemeMode.dark.subtitle,
                          isSelected: currentMode == AppThemeMode.dark,
                          onTap: () => themeController.setThemeMode(AppThemeMode.dark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildSectionTitle(context, 'PRATINJAU TEMA'),
                  Row(
                    children: [
                      // Pratinjau Terang
                      Expanded(
                        child: _buildThemePreviewCard(
                          context: context,
                          title: 'Terang',
                          isDarkTheme: false,
                          isSelected: currentMode == AppThemeMode.light,
                          onTap: () => themeController.setThemeMode(AppThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Pratinjau Gelap
                      Expanded(
                        child: _buildThemePreviewCard(
                          context: context,
                          title: 'Gelap',
                          isDarkTheme: true,
                          isSelected: currentMode == AppThemeMode.dark,
                          onTap: () => themeController.setThemeMode(AppThemeMode.dark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

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
            );
          },
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

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
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
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.textSecondary,
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

  Widget _buildThemePreviewCard({
    required BuildContext context,
    required String title,
    required bool isDarkTheme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.tulapColors;
    final cardBg = isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final innerSurface = isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final primaryAccent = isDarkTheme ? const Color(0xFF3B82F6) : const Color(0xFF0066FE);
    final previewBorder = isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textHeader = isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Thumbnail
            Container(
              height: 90,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: previewBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar preview
                  Container(
                    height: 14,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 24, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Card preview
                  Container(
                    height: 32,
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: innerSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: previewBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: textHeader, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 4),
                        Container(width: 20, height: 3, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
