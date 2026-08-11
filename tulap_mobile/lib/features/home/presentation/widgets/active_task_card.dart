import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';

/// ActiveTaskCard
/// ----------------------------------------------------------------------
/// "Kartu Tugas Aktif" sesuai Bagian 11.1 & wireframe Bagian 13: nama
/// tugas, lokasi, jadwal, progres checklist, CTA "Lanjutkan Tugas".
/// ----------------------------------------------------------------------
class ActiveTaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onContinue;

  const ActiveTaskCard({super.key, required this.task, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TUGAS AKTIF', style: AppTypography.small.copyWith(fontWeight: FontWeight.w700)),
              TaskStatusBanner(status: task.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(task.taskName, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(task.destination, style: AppTypography.bodySecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(_formatDate(task.endDate), style: AppTypography.bodySecondary),
            ],
          ),
          if (task.checklistItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.checklistProgress,
                backgroundColor: AppColors.background,
                color: AppColors.success,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${task.completedChecklistCount}/${task.checklistItems.length} selesai',
              style: AppTypography.small,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onContinue,
            child: const Text('Lanjutkan Tugas'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
