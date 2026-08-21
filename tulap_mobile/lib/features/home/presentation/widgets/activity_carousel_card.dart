import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';
import '../../domain/home_category.dart';

/// ActivityCarouselCard
/// ----------------------------------------------------------------------
/// Kartu carousel horizontal "Aktivitas Berjalan" - komposisi visual
/// diadaptasi dari pola kartu hero aplikasi referensi (panel gradien
/// besar di atas, identitas + progres di bawah), TAPI kontennya murni
/// data tugas Tulap.id (Task_SPPD) yang sudah ada. Tidak ada foto tugas
/// sungguhan di level Task (foto tersimpan per-bukti kegiatan, bukan
/// per-tugas) - jadi panel atas memakai gradien + ikon kategori sebagai
/// watermark, bukan foto acak yang menyesatkan.
/// ----------------------------------------------------------------------
class ActivityCarouselCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const ActivityCarouselCard({
    super.key,
    required this.task,
    required this.onTap,
  });

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
          width: 264,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerHeader(category: category, status: task.status),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
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
                      ],
                    ),
                    if (task.checklistItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: task.checklistProgress),
                          duration: AppMotion.card,
                          curve: AppMotion.standard,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            backgroundColor: AppColors.background,
                            color: AppColors.success,
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.completedChecklistCount}/${task.checklistItems.length} checklist selesai',
                        style: AppTypography.small.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerHeader extends StatelessWidget {
  final HomeCategory category;
  final TaskStatusEntity status;

  const _BannerHeader({required this.category, required this.status});

  IconData get _icon {
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
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -16,
            child: Icon(
              _icon,
              size: 90,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: AppSpacing.base,
            bottom: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                category.label,
                style: AppTypography.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: TaskStatusBanner(status: status),
          ),
        ],
      ),
    );
  }
}
