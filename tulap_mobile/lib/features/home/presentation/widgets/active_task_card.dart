import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';

/// ActiveTaskCard
/// ----------------------------------------------------------------------
/// "Kartu Tugas Aktif" sesuai Bagian 11.1 & wireframe Bagian 13: nama
/// tugas, lokasi, jadwal, progres checklist, CTA "Lanjutkan Tugas".
/// Kartu ini adalah pusat visual Beranda (Bagian 15) - shadow lembut,
/// tanpa border tebal (Bagian 7). Seluruh kartu bisa ditekan (bukan
/// hanya tombol CTA), dengan haptic ringan saat diketuk (Bagian 24 & 17).
/// ----------------------------------------------------------------------
class ActiveTaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onContinue;

  const ActiveTaskCard({super.key, required this.task, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onContinue();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: AppColors.shadowSoft, blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TUGAS AKTIF', style: AppTypography.sectionLabel),
                  TaskStatusBanner(status: task.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                task.taskName,
                style: AppTypography.sectionTitle.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(task.destination, style: AppTypography.bodySecondary.copyWith(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(_formatDate(task.endDate), style: AppTypography.bodySecondary.copyWith(fontSize: 14)),
                ],
              ),
              if (task.checklistItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                Text(
                  '${task.completedChecklistCount} dari ${task.checklistItems.length} selesai',
                  style: AppTypography.small.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: task.checklistProgress),
                    duration: AppMotion.card,
                    curve: AppMotion.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppColors.background,
                      color: AppColors.success,
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              ElevatedButton(
                onPressed: onContinue,
                child: const Text('Lanjutkan Tugas'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
