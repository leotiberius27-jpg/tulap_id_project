import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum LogoutDialogAction {
  cancel,
  syncNow,
  logoutNow,
}

/// LogoutProtectionDialog
/// ----------------------------------------------------------------------
/// Dialog konfirmasi keluar akun dengan perlindungan bukti outbox offline.
/// Memperingatkan pengguna jika masih ada foto/nota/catatan yang belum
/// tersinkronisasi ke server.
/// ----------------------------------------------------------------------
class LogoutProtectionDialog extends StatelessWidget {
  final int pendingCount;

  const LogoutProtectionDialog({super.key, required this.pendingCount});

  static Future<LogoutDialogAction?> show(
    BuildContext context, {
    required int pendingCount,
  }) {
    return showDialog<LogoutDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LogoutProtectionDialog(pendingCount: pendingCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasPending ? AppColors.warningSoft : AppColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPending ? Icons.warning_amber_rounded : Icons.logout_rounded,
              color: hasPending ? AppColors.warning : AppColors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasPending ? 'Peringatan Sinkronisasi' : 'Keluar dari Akun',
              style: AppTypography.sectionTitle.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPending) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Masih ada $pendingCount data yang belum tersinkronisasi.',
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Dokumentasi dan bukti lapangan Anda tetap tersimpan aman di database lokal perangkat ini. Namun disarankan untuk menyinkronkan data sebelum berganti perangkat.',
              style: AppTypography.small.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'Apakah Anda yakin ingin keluar dari akun Tulap.id pada perangkat ini?',
              style: AppTypography.body.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (hasPending) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(LogoutDialogAction.cancel),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(LogoutDialogAction.syncNow),
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Sinkronkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(LogoutDialogAction.logoutNow),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tetap Keluar'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(LogoutDialogAction.cancel),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(LogoutDialogAction.logoutNow),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ],
    );
  }
}
