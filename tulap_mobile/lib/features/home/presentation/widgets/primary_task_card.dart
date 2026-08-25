import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';

/// PrimaryTaskCard (Tugas Utama)
/// ----------------------------------------------------------------------
/// Kartu Tugas Utama di Beranda Tulap.id:
/// - Foto cover kegiatan / evidence terbaru (aspectRatio 16:9)
/// - Badge status tugas (Sedang Berjalan, Perlu Diperbaiki, dsb)
/// - Judul tugas (maksimal 2 baris tanpa overflow)
/// - Lokasi kegiatan
/// - Counter checklist & dokumentasi bukti + progress bar
/// - Tombol CTA aksi utama "Lanjutkan Tugas →"
/// ----------------------------------------------------------------------
class PrimaryTaskCard extends StatelessWidget {
  final TaskEntity task;
  final String? coverPhotoPath;
  final VoidCallback onTap;
  final VoidCallback onSeeAll;

  const PrimaryTaskCard({
    super.key,
    required this.task,
    this.coverPhotoPath,
    required this.onTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 380;
    final totalChecklist = task.checklistItems.length;
    final completedChecklist = task.completedChecklistCount;
    final progress = task.checklistProgress;
    final progressPercent = (progress * 100).round();
    final colors = context.tulapColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Tugas Utama & Lihat Semua
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Tugas Utama',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
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
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Main Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowSoft,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: colors.border, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cover Image (Aspect Ratio 16:9)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCoverImage(context),
                          // Gradient scrim for top status
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45],
                                ),
                              ),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            top: AppSpacing.md,
                            left: AppSpacing.md,
                            child: TaskStatusBanner(status: task.status),
                          ),
                          // Photo Count Badge
                          if (task.geotagPhotoCount > 0)
                            Positioned(
                              top: AppSpacing.md,
                              right: AppSpacing.md,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
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
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${task.geotagPhotoCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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

                    // 2. Info Section
                    Padding(
                      padding: EdgeInsets.all(
                        isSmallScreen ? 12 : AppSpacing.base,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task Name
                          Text(
                            task.taskName,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.destination,
                                  style: AppTypography.small.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Checklist & Documentation Counter + Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  totalChecklist > 0
                                      ? '$completedChecklist/$totalChecklist Checklist  •  ${task.geotagPhotoCount} Dokumentasi'
                                      : '${task.geotagPhotoCount} Dokumentasi Foto',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$progressPercent%',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colors.border,
                              color: progress >= 1.0
                                  ? colors.success
                                  : colors.action,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),

                          // 3. CTA Button "Lanjutkan Tugas →"
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.action,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.button,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Lanjutkan Tugas',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (coverPhotoPath != null && coverPhotoPath!.isNotEmpty) {
      if (coverPhotoPath!.startsWith('http')) {
        return Image.network(
          coverPhotoPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCover(context),
        );
      }
      final file = File(coverPhotoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCover(context),
        );
      }
    }
    return _buildFallbackCover(context);
  }

  Widget _buildFallbackCover(BuildContext context) {
    final colors = context.tulapColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroGradientStart, colors.heroGradientEnd],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 42,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada dokumentasi',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
