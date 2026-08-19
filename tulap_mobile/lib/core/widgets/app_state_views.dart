import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AppLoadingView / AppEmptyState / AppErrorState
/// ----------------------------------------------------------------------
/// Fase 16 (master prompt): sebelum ini setiap halaman menulis ulang
/// `Center(child: CircularProgressIndicator())` polos (tanpa label) dan
/// widget empty/error state privat sendiri-sendiri dengan gaya yang
/// sedikit berbeda-beda (lihat riwayat: task_list_page, sync_center_page,
/// home_page semua punya versi masing-masing). Tiga widget ini adalah
/// satu-satunya sumber gaya loading/empty/error di seluruh app - halaman
/// hanya mengisi ikon/judul/pesan/aksi yang spesifik ke konteksnya.
/// ----------------------------------------------------------------------
class AppLoadingView extends StatelessWidget {
  final String? label;

  const AppLoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(label!, style: AppTypography.bodySecondary),
          ],
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color iconColor;
  final Color iconBackground;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor = AppColors.textSecondary,
    this.iconBackground = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.sectionTitle, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(message!, style: AppTypography.bodySecondary, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color iconColor;
  final String retryLabel;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_outlined,
    this.iconColor = AppColors.textSecondary,
    this.retryLabel = 'Coba Lagi',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTypography.bodySecondary, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
