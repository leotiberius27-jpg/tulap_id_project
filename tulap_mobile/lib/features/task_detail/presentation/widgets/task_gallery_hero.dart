import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import '../../../evidence_verification/presentation/pages/evidence_detail_page.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../domain/entities/task_entity.dart';
import 'task_status_banner.dart';

/// TaskGalleryHero
/// ----------------------------------------------------------------------
/// Panel galeri carousel di puncak Detail Tugas:
/// 1. Mulai dari foto pertama (index 0).
/// 2. Paging horizontal stabil: foto 1 ↔ 2 ↔ 3 ↔ 4.
/// 3. Preload foto berikutnya & sebelumnya untuk mencegah layar blank/kedip.
/// 4. Indikator foto (📷 X/N) & dots indicator berasal dari array foto yang sama.
/// 5. Seluruh overlay gradien & badge dibungkus IgnorePointer agar gesture
///    swipe horizontal maupun scroll vertikal halaman berjalan alami.
/// 6. Dukungan multi-sumber: File lokal, Remote URL (network), dan Bundle Assets.
/// 7. Mode tampilan: BoxFit.cover pada hero, dan BoxFit.contain pada fullscreen viewer.
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
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Memastikan carousel selalu mulai dari foto pertama (index 0)
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentImages();
    });
  }

  @override
  void didUpdateWidget(covariant TaskGalleryHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.photos.length && widget.photos.isNotEmpty) {
      setState(() => _page = widget.photos.length - 1);
    }
    _preloadAdjacentImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Preload foto sebelum & sesudah foto aktif untuk performa cepat
  void _preloadAdjacentImages() {
    if (!mounted || widget.photos.isEmpty) return;
    for (final idx in [_page - 1, _page + 1]) {
      if (idx >= 0 && idx < widget.photos.length) {
        final path = widget.photos[idx].localFilePath;
        try {
          if (path.startsWith('http://') || path.startsWith('https://')) {
            precacheImage(NetworkImage(path), context);
          } else if (path.startsWith('assets/')) {
            precacheImage(AssetImage(path), context);
          } else {
            final file = File(path);
            if (file.existsSync()) {
              precacheImage(FileImage(file), context);
            }
          }
        } catch (_) {
          // Abaikan error precache agar tidak mengganggu rendering utama
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = widget.photos.length;
    final hasPhotos = photoCount > 0;
    final activePhoto = hasPhotos
        ? widget.photos[_page.clamp(0, photoCount - 1)]
        : null;

    return SizedBox(
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Layer Viewport Carousel Horizontal (PageView)
          if (hasPhotos)
            PageView.builder(
              controller: _pageController,
              itemCount: photoCount,
              physics: photoCount > 1
                  ? const PageScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _page = i);
                _preloadAdjacentImages();
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openFullscreenImage(context, photo),
                  child: _PhotoItem(photo: photo, fit: BoxFit.cover),
                );
              },
            )
          else
            const _GalleryFallback(),

          // 2. Layer Gradien Pelindung Kontras Teks (IgnorePointer agar gesture tembus)
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x8A000000), // Top shadow ~54%
                      Colors.transparent,
                      Color(0x99000000), // Bottom shadow ~60%
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Layer Navigasi Atas (Tombol Kembali & Banner Status Tugas)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: widget.onBack,
                  ),
                  TaskStatusBanner(status: widget.task.status),
                ],
              ),
            ),
          ),

          // 4. Layer Caption / Info GPS Singkat di Kiri Bawah
          if (activePhoto != null)
            Positioned(
              bottom: 12,
              left: AppSpacing.base,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activePhoto.caption ??
                              '±${activePhoto.gpsAccuracyMeters.round()}m • GPS Valid',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Layer Dots Indicator (Hanya tampil jika foto > 1)
          if (photoCount > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photoCount, (i) {
                    final isActive = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: isActive
                            ? const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),

          // 6. Layer Counter Badge Dinamis (📷 X/N)
          if (hasPhotos)
            Positioned(
              bottom: 12,
              right: AppSpacing.base,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_page + 1}/$photoCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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

  void _openFullscreenImage(BuildContext context, GeotagPhotoEntity photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvidenceViewerPage(
          initialEvidenceList: widget.photos,
          initialIndex: _page,
          taskId: widget.task.id,
          taskName: widget.task.taskName,
          task: widget.task,
        ),
      ),
    );
  }
}

/// _PhotoItem
/// ----------------------------------------------------------------------
/// Komponen cerdas perender gambar multi-sumber:
/// 1. Remote URL (http:// / https://)
/// 2. Asset Bundle (assets/...)
/// 3. File Lokal di Device Storage
/// ----------------------------------------------------------------------
class _PhotoItem extends StatelessWidget {
  final GeotagPhotoEntity photo;
  final BoxFit fit;

  const _PhotoItem({required this.photo, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final path = photo.localFilePath;

    // Sumber 1: Remote HTTP/HTTPS
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF0F172A),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006EE6),
                strokeWidth: 2.5,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    // Sumber 2: Asset Bundle
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    // Sumber 3: Local File di Device Storage
    final file = File(path);
    return Image.file(
      file,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              color: Colors.white38,
              size: 36,
            ),
            const SizedBox(height: 6),
            Text(
              photo.caption ?? 'Foto bukti kegiatan',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
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
              'Belum ada bukti kegiatan',
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
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
