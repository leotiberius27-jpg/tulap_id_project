import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/map/map_launcher_service.dart';
import '../../../../core/media/media_share_service.dart';
import '../../../evidence_verification/presentation/pages/evidence_detail_page.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/usecases/delete_evidence.dart';
import '../widgets/evidence_photo_viewer_widget.dart';
import '../widgets/evidence_video_player_widget.dart';

/// EvidenceViewerPage
/// ----------------------------------------------------------------------
/// Layanan penampil media bukti (Foto & Video) layar penuh:
/// 1. Membuka media terbaru pertama kali secara default (newest first).
/// 2. Swipe horizontal antar foto & video campuran secara responsif.
/// 3. Pinch-to-zoom & pan foto; pemutar video dengan seekbar & auto-pause.
/// 4. Indikator halaman halus (mis. `3 / 8`).
/// 5. Top Bar & Bottom Action Bar (Detail, Lokasi Maps, Bagikan, Hapus).
/// 6. Aksi hapus aman (safe deletion) dengan konfirmasi destruktif.
/// 7. Kontinuitas kembali ke kamera seketika.
/// ----------------------------------------------------------------------
class EvidenceViewerPage extends StatefulWidget {
  final List<GeotagPhotoEntity> initialEvidenceList;
  final int initialIndex;
  final String taskId;
  final String? taskName;
  final TaskEntity? task;

  const EvidenceViewerPage({
    super.key,
    required this.initialEvidenceList,
    this.initialIndex = 0,
    required this.taskId,
    this.taskName,
    this.task,
  });

  @override
  State<EvidenceViewerPage> createState() => _EvidenceViewerPageState();
}

class _EvidenceViewerPageState extends State<EvidenceViewerPage> {
  late final PageController _pageController;
  late List<GeotagPhotoEntity> _evidenceList;
  late int _currentIndex;
  bool _areControlsVisible = true;
  bool _isZoomed = false;

  late final MapLauncherService _mapLauncherService;
  late final MediaShareService _mediaShareService;
  late final DeleteEvidence _deleteEvidence;

  @override
  void initState() {
    super.initState();
    _evidenceList = List.from(widget.initialEvidenceList);
    _currentIndex = widget.initialIndex.clamp(
      0,
      _evidenceList.isNotEmpty ? _evidenceList.length - 1 : 0,
    );
    _pageController = PageController(initialPage: _currentIndex);

    _mapLauncherService = sl<MapLauncherService>();
    _mediaShareService = sl<MediaShareService>();
    _deleteEvidence = sl<DeleteEvidence>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _areControlsVisible = !_areControlsVisible);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });
  }

  Future<void> _openGoogleMaps(GeotagPhotoEntity photo) async {
    final success = await _mapLauncherService.openGoogleMaps(
      latitude: photo.latitude,
      longitude: photo.longitude,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak dapat dibuka.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _shareEvidence(GeotagPhotoEntity photo) async {
    final success = await _mediaShareService.shareEvidence(
      evidence: photo,
      taskName: widget.taskName ?? widget.task?.taskName,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media tidak tersedia pada perangkat.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _navigateToDetail(GeotagPhotoEntity photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvidenceDetailPage(
          photo: photo,
          task: widget.task,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEvidence(GeotagPhotoEntity photo) async {
    HapticFeedback.mediumImpact();
    final taskTitle = widget.taskName ?? widget.task?.taskName ?? 'kegiatan ini';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Hapus Bukti?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Foto/video ini akan dihapus dari kegiatan "$taskTitle".',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _deleteEvidence(evidenceId: photo.id);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        (_) {
          if (!mounted) return;
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bukti berhasil dihapus.'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );

          setState(() {
            _evidenceList.removeAt(_currentIndex);
            if (_evidenceList.isEmpty) {
              _currentIndex = 0;
            } else if (_currentIndex >= _evidenceList.length) {
              _currentIndex = _evidenceList.length - 1;
            }
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_evidenceList.isEmpty) {
      return _buildEmptyState();
    }

    final currentEvidence = _evidenceList[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Media PageView (Photo / Video Swiper)
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            itemCount: _evidenceList.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final evidence = _evidenceList[index];
              final isActive = index == _currentIndex;

              if (evidence.isVideo) {
                return EvidenceVideoPlayerWidget(
                  key: ValueKey(evidence.id),
                  evidence: evidence,
                  isActive: isActive,
                  onToggleControls: _toggleControls,
                );
              } else {
                return EvidencePhotoViewerWidget(
                  key: ValueKey(evidence.id),
                  evidence: evidence,
                  onToggleControls: _toggleControls,
                  onZoomStateChanged: (zoomed) {
                    setState(() => _isZoomed = zoomed);
                  },
                );
              }
            },
          ),

          // 2. Top Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _areControlsVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                bottom: 12,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pratinjau',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} / ${_evidenceList.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    onSelected: (value) {
                      if (value == 'detail') {
                        _navigateToDetail(currentEvidence);
                      } else if (value == 'delete') {
                        _confirmDeleteEvidence(currentEvidence);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Detail Bukti',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Hapus Bukti',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _areControlsVisible ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomActionButton(
                    icon: Icons.info_outline_rounded,
                    label: 'Detail',
                    onTap: () => _navigateToDetail(currentEvidence),
                  ),
                  _buildBottomActionButton(
                    icon: Icons.map_outlined,
                    label: 'Lokasi',
                    onTap: () => _openGoogleMaps(currentEvidence),
                  ),
                  _buildBottomActionButton(
                    icon: Icons.share_rounded,
                    label: 'Bagikan',
                    onTap: () => _shareEvidence(currentEvidence),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1120),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Pratinjau'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF006EE6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Dokumentasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Foto atau video yang Anda ambil untuk kegiatan ini akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006EE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text(
                  'Ambil Dokumentasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
