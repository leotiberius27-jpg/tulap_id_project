import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';
import '../../domain/home_category.dart';

/// MyActivityTile
/// ----------------------------------------------------------------------
/// Baris daftar vertikal "Kegiatan Saya" di Beranda - ikon kategori bulat
/// + identitas ringkas + status, mengikuti pola list item aplikasi
/// referensi tapi dengan konten Tulap.id (nama tugas, tujuan, tanggal,
/// status verifikasi lapangan).
/// ----------------------------------------------------------------------
class MyActivityTile extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const MyActivityTile({super.key, required this.task, required this.onTap});

  IconData _iconFor(HomeCategory category) {
    switch (category) {
      case HomeCategory.perjalananDinas:
        return Icons.card_travel;
      case HomeCategory.inspeksi:
        return Icons.fact_check_outlined;
      case HomeCategory.survei:
        return Icons.map_outlined;
      case HomeCategory.lainnya:
      case HomeCategory.semua:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = categorizeTask(task);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.iconSoftBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(category), color: AppColors.action, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.taskName,
                            style: AppTypography.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        TaskStatusBanner(status: task.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.destination,
                            style: AppTypography.small,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatDate(task.endDate),
                          style: AppTypography.small.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
