import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';

/// DisplaySettingsPage (Akun -> Tampilan)
/// ----------------------------------------------------------------------
/// Pengaturan tema tampilan global (Sistem, Terang, Gelap).
/// Perubahan tema diterapkan secara instan ke seluruh aplikasi dan
/// tersimpan secara persisten ke local storage.
/// ----------------------------------------------------------------------
class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
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

                  _buildSectionTitle(context, 'VISUALISASI KONTRAS LAPANGAN'),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desain Tulap.id dirancang dengan palet institusional berbasis Dark Navy (#0B1220) untuk kondisi minim cahaya dan Light Crisp (#F7F9FC) untuk siang hari di lapangan agar tulisan, watermark, dan tombol aksi tetap terbaca dengan jelas.',
                          style: AppTypography.small.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _buildColorSample(context, 'Primary', colors.primary, Colors.white),
                            const SizedBox(width: 8),
                            _buildColorSample(context, 'Action', colors.action, Colors.white),
                            const SizedBox(width: 8),
                            _buildColorSample(context, 'Success', colors.success, Colors.white),
                            const SizedBox(width: 8),
                            _buildColorSample(
                              context,
                              'Surface',
                              colors.surface,
                              colors.textPrimary,
                              hasBorder: true,
                            ),
                          ],
                        ),
                      ],
                    ),
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
    final cardBg = isDarkTheme ? const Color(0xFF0B1220) : const Color(0xFFF7F9FC);
    final innerSurface = isDarkTheme ? const Color(0xFF111C2E) : const Color(0xFFFFFFFF);
    final primaryAccent = isDarkTheme ? const Color(0xFF4DA3FF) : const Color(0xFF00529C);
    final previewBorder = isDarkTheme ? const Color(0xFF27364B) : const Color(0xFFEAECF0);
    final textHeader = isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF172033);

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

  Widget _buildColorSample(
    BuildContext context,
    String name,
    Color bg,
    Color text, {
    bool hasBorder = false,
  }) {
    final colors = context.tulapColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: hasBorder ? Border.all(color: colors.border) : null,
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
