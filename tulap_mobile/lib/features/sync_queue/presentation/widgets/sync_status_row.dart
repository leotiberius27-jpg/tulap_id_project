import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sync_record_entity.dart';

/// SyncStatusRow
/// ----------------------------------------------------------------------
/// Satu baris di Sync Center, menampilkan jenis data, status chip
/// (Tersimpan/Menunggu Internet/Mengirim/Terkirim/Gagal), dan tombol
/// retry jika status Gagal. Selaras dengan Bagian 10 & 25 spesifikasi.
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_entityTypeLabel(record.entityType), style: AppTypography.body),
                const SizedBox(height: 2),
                Text(config.label, style: AppTypography.small.copyWith(color: config.color)),
                if (record.status == SyncStatus.failed &&
                    record.lastErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      record.lastErrorMessage!,
                      style: AppTypography.small,
                    ),
                  ),
              ],
            ),
          ),
          if (record.status == SyncStatus.failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba Kirim Lagi'),
            ),
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
        return _SyncStatusConfig('Tersimpan', Icons.save_outlined, AppColors.textSecondary);
      case SyncStatus.waitingForInternet:
        return _SyncStatusConfig('Menunggu Internet', Icons.wifi_off, AppColors.warning);
      case SyncStatus.uploading:
        return _SyncStatusConfig('Sedang Mengirim', Icons.cloud_upload_outlined, AppColors.action);
      case SyncStatus.synced:
        return _SyncStatusConfig('Terkirim', Icons.check_circle, AppColors.success);
      case SyncStatus.failed:
        return _SyncStatusConfig('Gagal Terkirim', Icons.error_outline, AppColors.danger);
    }
  }
}

class _SyncStatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  _SyncStatusConfig(this.label, this.icon, this.color);
}
