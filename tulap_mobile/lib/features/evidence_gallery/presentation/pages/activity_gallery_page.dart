import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/usecases/get_activity_evidence.dart';
import 'evidence_viewer_page.dart';

enum GalleryMediaTypeFilter { all, photo, video }

/// ActivityGalleryPage
/// ----------------------------------------------------------------------
/// Halaman Galeri Dokumentasi Kegiatan Lengkap:
/// 1. Grid 3-kolom responsif untuk semua bukti foto & video kegiatan.
/// 2. Filter kompak: Semua, Foto, Video.
/// 3. Thumbnail video dilengkapi badge durasi dan ikon putar.
/// 4. Tap pada item membuka EvidenceViewerPage langsung pada posisi media tersebut.
/// 5. Sumber data utama lokal SQLite offline-first yang cepat.
/// ----------------------------------------------------------------------
class ActivityGalleryPage extends StatefulWidget {
  final String taskId;
  final String? taskName;
  final TaskEntity? task;

  const ActivityGalleryPage({
    super.key,
    required this.taskId,
    this.taskName,
    this.task,
  });

  @override
  State<ActivityGalleryPage> createState() => _ActivityGalleryPageState();
}

class _ActivityGalleryPageState extends State<ActivityGalleryPage> {
  late final GetActivityEvidence _getActivityEvidence;
  List<GeotagPhotoEntity> _allEvidence = [];
  bool _isLoading = true;
  String? _errorMessage;
  GalleryMediaTypeFilter _selectedFilter = GalleryMediaTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _getActivityEvidence = sl<GetActivityEvidence>();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getActivityEvidence(widget.taskId);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (evidenceList) => setState(() {
        _isLoading = false;
        _allEvidence = evidenceList;
      }),
    );
  }

  List<GeotagPhotoEntity> get _filteredEvidence {
    switch (_selectedFilter) {
      case GalleryMediaTypeFilter.photo:
        return _allEvidence.where((e) => e.isPhoto).toList();
      case GalleryMediaTypeFilter.video:
        return _allEvidence.where((e) => e.isVideo).toList();
      case GalleryMediaTypeFilter.all:
      default:
        return _allEvidence;
    }
  }

  void _openViewer(int index) {
    final filtered = _filteredEvidence;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => EvidenceViewerPage(
              initialEvidenceList: filtered,
              initialIndex: index,
              taskId: widget.taskId,
              taskName: widget.taskName ?? widget.task?.taskName,
              task: widget.task,
            ),
          ),
        )
        .then((_) => _loadEvidence());
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredEvidence;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Galeri Dokumentasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.taskName ?? widget.task?.taskName ?? 'Kegiatan Lapangan',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Filter Chips & Counter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua (${_allEvidence.length})',
                  filter: GalleryMediaTypeFilter.all,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Foto (${_allEvidence.where((e) => e.isPhoto).length})',
                  filter: GalleryMediaTypeFilter.photo,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Video (${_allEvidence.where((e) => e.isVideo).length})',
                  filter: GalleryMediaTypeFilter.video,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 2. Grid Content / Loading / Error
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006EE6),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? _buildEmptyGalleryState(isDark)
                        : RefreshIndicator(
                            onRefresh: _loadEvidence,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildGalleryGridItem(
                                  filtered[index],
                                  index,
                                  isDark,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required GalleryMediaTypeFilter filter,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF006EE6)
              : (isDark ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGridItem(
    GeotagPhotoEntity evidence,
    int index,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _openViewer(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnailImage(evidence),

              // Video Indicator Overlay
              if (evidence.isVideo)
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(evidence.durationSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildThumbnailImage(GeotagPhotoEntity evidence) {
    final path = evidence.localFilePath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackThumbnail(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackThumbnail(),
      );
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildFallbackThumbnail();
      }
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackThumbnail(),
      );
    }
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          color: Colors.white38,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildEmptyGalleryState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada bukti',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Foto dan video kegiatan lapangan akan terkumpul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
