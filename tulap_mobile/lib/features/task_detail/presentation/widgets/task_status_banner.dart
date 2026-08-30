import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

/// TaskStatusBanner
/// ----------------------------------------------------------------------
/// Menampilkan status tugas dalam bahasa manusiawi sesuai Bagian 25
/// spesifikasi (chip status): Belum Dimulai, Sedang Berjalan, Menunggu
/// Verifikasi, Perlu Diperbaiki, Selesai.
/// ----------------------------------------------------------------------
class TaskStatusBanner extends StatelessWidget {
  final TaskStatusEntity status;

  const TaskStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTypography.small.copyWith(
              color: config.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _configFor(TaskStatusEntity status) {
    switch (status) {
      case TaskStatusEntity.draft:
        return _StatusConfig(
          'Belum Dimulai',
          Icons.hourglass_empty,
          AppColors.textSecondary,
          AppColors.background,
        );
      case TaskStatusEntity.ongoing:
        return _StatusConfig(
          'Sedang Berjalan',
          Icons.directions_walk,
          AppColors.primary,
          AppColors.iconSoftBlue,
        );
      case TaskStatusEntity.pendingVerification:
        return _StatusConfig(
          'Menunggu Verifikasi',
          Icons.hourglass_top,
          AppColors.warning,
          AppColors.warningSoft,
        );
      case TaskStatusEntity.revisionNeeded:
        return _StatusConfig(
          'Perlu Diperbaiki',
          Icons.edit_note,
          AppColors.warning,
          AppColors.warningSoft,
        );
      case TaskStatusEntity.verified:
        return _StatusConfig(
          'Disetujui',
          Icons.verified,
          AppColors.success,
          AppColors.successSoft,
        );
      case TaskStatusEntity.rejected:
        return _StatusConfig(
          'Ditolak',
          Icons.cancel,
          AppColors.danger,
          AppColors.dangerSoft,
        );
      case TaskStatusEntity.completed:
        return _StatusConfig(
          'Selesai',
          Icons.check_circle,
          AppColors.success,
          AppColors.successSoft,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  _StatusConfig(this.label, this.icon, this.foreground, this.background);
}
