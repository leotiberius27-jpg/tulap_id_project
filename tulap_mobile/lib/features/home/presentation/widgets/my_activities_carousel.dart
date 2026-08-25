import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';

/// MyActivitiesCarousel (Kegiatan Saya — Horizontal Carousel)
/// ----------------------------------------------------------------------
/// Menampilkan maksimal 5 kegiatan prioritas:
/// - Lebar kartu adaptif (~74% lebar viewport) sehingga kartu kedua
///   terlihat sebagian (20–26%) untuk mengindikasikan scroll horizontal.
/// - Menampilkan foto bukti (jika ada), status, jumlah foto (📷 X),
///   nama tugas, lokasi, dan tanggal.
/// - Tap kartu langsung membuka Detail Kegiatan.
/// ----------------------------------------------------------------------
class MyActivitiesCarousel extends StatelessWidget {
  final List<TaskEntity> activities;
  final Map<String, String?> taskPhotos;
  final Function(TaskEntity task) onTaskTap;
  final VoidCallback onSeeAll;

  const MyActivitiesCarousel({
    super.key,
    required this.activities,
    this.taskPhotos = const {},
    required this.onTaskTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;

    // Maksimal 5 kegiatan
    final displayTasks = activities.take(5).toList();

    // Hitung lebar kartu agar kartu ke-2 terlihat ~20-26%
    final cardWidth = (screenWidth * 0.74).clamp(240.0, 310.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Kegiatan Saya & Lihat Semua
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Kegiatan Saya',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(48, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.action,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Horizontal Carousel
        if (displayTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Belum ada kegiatan.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 242,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              itemCount: displayTasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final task = displayTasks[index];
                final photoPath = taskPhotos[task.id];
                return _ActivityCard(
                  task: task,
                  photoPath: photoPath,
                  width: cardWidth,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTaskTap(task);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final TaskEntity task;
  final String? photoPath;
  final double width;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.task,
    this.photoPath,
    required this.width,
    required this.onTap,
  });

  String _formatIndonesianDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final m = (date.month >= 1 && date.month <= 12)
        ? months[date.month - 1]
        : 'Agu';
    return '${date.day} $m ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatIndonesianDate(task.startDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cover Photo / Header
              SizedBox(
                height: 104,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageHeader(),
                    // Top gradient scrim
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: TaskStatusBanner(status: task.status),
                    ),
                    // Photo count badge
                    if (task.geotagPhotoCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${task.geotagPhotoCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Task Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Task Name (Max 2 lines)
                      Text(
                        task.taskName,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location
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
                                  style: AppTypography.small.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Date
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: AppTypography.small.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    if (photoPath != null && photoPath!.isNotEmpty) {
      if (photoPath!.startsWith('http')) {
        return Image.network(
          photoPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackHeader(),
        );
      }
      final file = File(photoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackHeader(),
        );
      }
    }
    return _buildFallbackHeader();
  }

  Widget _buildFallbackHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.assignment_outlined,
          size: 32,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
