import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// SyncStatusBanner
/// ----------------------------------------------------------------------
/// Copy PERSIS sesuai Bagian 19 (Offline UX): "Tidak Ada Internet -
/// Pekerjaan Anda tetap tersimpan di perangkat. X data menunggu
/// dikirim." dengan CTA "Lihat Data" menuju Sync Center. Saat semua
/// data sudah terkirim, tampilkan konfirmasi tenang alih-alih banner
/// peringatan, sesuai Bagian 34 (Empty States: Sync Center).
/// ----------------------------------------------------------------------
class SyncStatusBanner extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final bool allSynced;
  final VoidCallback onViewData;

  const SyncStatusBanner({
    super.key,
    required this.isOffline,
    required this.pendingCount,
    required this.allSynced,
    required this.onViewData,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Semua data sudah terkirim',
                style: AppTypography.small.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final message = isOffline
        ? 'Tidak Ada Internet — Pekerjaan Anda tetap tersimpan di perangkat. $pendingCount data menunggu dikirim.'
        : '$pendingCount data menunggu dikirim.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.small.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onViewData, child: const Text('Lihat Data')),
          ),
        ],
      ),
    );
  }
}
