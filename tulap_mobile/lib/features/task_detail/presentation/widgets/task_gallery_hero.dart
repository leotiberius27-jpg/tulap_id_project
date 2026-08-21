import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../domain/entities/task_entity.dart';
import 'task_status_banner.dart';

/// TaskGalleryHero
/// ----------------------------------------------------------------------
/// Panel galeri di puncak Detail Tugas - memakai foto bukti kegiatan
/// SUNGGUHAN yang sudah tersimpan lokal (`GeotagPhotoEntity.localFilePath`,
/// lihat `GetTaskPhotoPreviews`), bukan placeholder acak. Kalau belum ada
/// foto sama sekali (tugas baru/DRAFT), tampil panel gradien dengan ikon -
/// bukan foto palsu yang menyesatkan pegawai soal bukti apa yang sudah
/// benar-benar tersimpan.
/// ----------------------------------------------------------------------
class TaskGalleryHero extends StatefulWidget {
  final List<GeotagPhotoEntity> photos;
  final TaskEntity task;
  final VoidCallback onBack;

  const TaskGalleryHero({
    super.key,
    required this.photos,
    required this.task,
    required this.onBack,
  });

  @override
  State<TaskGalleryHero> createState() => _TaskGalleryHeroState();
}

class _TaskGalleryHeroState extends State<TaskGalleryHero> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.photos.isNotEmpty;

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhotos)
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return Image.file(
                  File(photo.localFilePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _GalleryFallback(),
                );
              },
            )
          else
            const _GalleryFallback(),

          // Gradien gelap tipis di atas & bawah agar tombol back/status
          // tetap terbaca di atas foto apa pun (Bagian 7 - kontras teks).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black38, Colors.transparent, Colors.black45],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(icon: Icons.arrow_back, onTap: widget.onBack),
                  TaskStatusBanner(status: widget.task.status),
                ],
              ),
            ),
          ),

          if (hasPhotos && widget.photos.length > 1)
            Positioned(
              bottom: AppSpacing.sm,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  final isActive = i == _page;
                  return AnimatedContainer(
                    duration: AppMotion.stateChange,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isActive ? 1 : 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),

          if (hasPhotos)
            Positioned(
              bottom: AppSpacing.sm,
              right: AppSpacing.base,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_page + 1}/${widget.photos.length}',
                      style: AppTypography.small.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: Colors.white54, size: 44),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada foto bukti kegiatan',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}
