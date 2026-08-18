import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sync_record_entity.dart';

/// SyncStatusRow
/// ----------------------------------------------------------------------
/// Satu baris di Sync Center, menampilkan jenis data, status chip
/// (Tersimpan/Menunggu Internet/Mengirim/Terkirim/Gagal), dan tombol
/// retry jika status Gagal. Selaras dengan Bagian 10 & 25 spesifikasi.
/// Kartu memakai shadow lembut (bukan border) dan status ditampilkan
/// sebagai chip soft, konsisten dengan TaskStatusBanner (Bagian 17 & 23:
/// semua status chip di aplikasi memakai sistem visual yang sama).
/// ----------------------------------------------------------------------
class SyncStatusRow extends StatelessWidget {
  final SyncRecordEntity record;
  final VoidCallback? onRetry;

  const SyncStatusRow({super.key, required this.record, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(record.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: config.softBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entityTypeLabel(record.entityType),
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: config.softBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    config.label,
                    style: AppTypography.small.copyWith(
                      color: config.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (record.status == SyncStatus.failed &&
                    record.lastErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      record.lastErrorMessage!,
                      style: AppTypography.small,
                    ),
                  ),
              ],
            ),
          ),
          if (record.status == SyncStatus.failed && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  String _entityTypeLabel(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.geotagPhoto:
        return 'Foto Kegiatan';
      case SyncEntityType.expenseNote:
        return 'Nota Pengeluaran';
      case SyncEntityType.taskChecklist:
        return 'Checklist Tugas';
    }
  }

  _SyncStatusConfig _statusConfig(SyncStatus status) {
    switch (status) {
      case SyncStatus.pendingUpload:
        return _SyncStatusConfig(
          'Tersimpan',
          Icons.save_outlined,
          AppColors.textSecondary,
          AppColors.background,
        );
      case SyncStatus.waitingForInternet:
        return _SyncStatusConfig(
          'Menunggu Internet',
          Icons.wifi_off,
          AppColors.warning,
          AppColors.warningSoft,
        );
      case SyncStatus.uploading:
        return _SyncStatusConfig(
          'Sedang Mengirim',
          Icons.cloud_upload_outlined,
          AppColors.action,
          AppColors.iconSoftBlue,
        );
      case SyncStatus.synced:
        return _SyncStatusConfig(
          'Terkirim',
          Icons.check_circle,
          AppColors.success,
          AppColors.successSoft,
        );
      case SyncStatus.failed:
        return _SyncStatusConfig(
          'Gagal Terkirim',
          Icons.error_outline,
          AppColors.danger,
          AppColors.dangerSoft,
        );
    }
  }
}

class _SyncStatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color softBackground;
  _SyncStatusConfig(this.label, this.icon, this.color, this.softBackground);
}
