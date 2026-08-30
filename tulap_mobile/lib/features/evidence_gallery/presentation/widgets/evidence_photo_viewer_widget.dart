import 'dart:io';
import 'package:flutter/material.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';

/// EvidencePhotoViewerWidget
/// ----------------------------------------------------------------------
/// Komponen penampil foto bukti resolusi penuh dengan:
/// - Pinch-to-zoom (1.0x - 4.0x) dan double-tap zoom (1.0x <-> 2.5x).
/// - Pan halus saat posisi diperbesar tanpa mengganggu gesture swipe halaman.
/// - Menjaga rasio aspek foto asli (BoxFit.contain).
/// - Penanganan anggun jika file lokal tidak ditemukan atau rusak.
/// ----------------------------------------------------------------------
class EvidencePhotoViewerWidget extends StatefulWidget {
  final GeotagPhotoEntity evidence;
  final VoidCallback? onToggleControls;
  final ValueChanged<bool>? onZoomStateChanged;

  const EvidencePhotoViewerWidget({
    super.key,
    required this.evidence,
    this.onToggleControls,
    this.onZoomStateChanged,
  });

  @override
  State<EvidencePhotoViewerWidget> createState() =>
      _EvidencePhotoViewerWidgetState();
}

class _EvidencePhotoViewerWidgetState extends State<EvidencePhotoViewerWidget>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.05;
    if (isZoomed != _isZoomed) {
      setState(() => _isZoomed = isZoomed);
      widget.onZoomStateChanged?.call(isZoomed);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_zoomAnimation != null && _animationController.isAnimating) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetMatrix = Matrix4.identity();

    if (currentScale < 1.5) {
      // Zoom in to 2.5x at tap position
      final position = details.localPosition;
      targetMatrix.setEntry(0, 0, 2.5);
      targetMatrix.setEntry(1, 1, 2.5);
      targetMatrix.setEntry(0, 3, -position.dx * 1.5);
      targetMatrix.setEntry(1, 3, -position.dy * 1.5);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0).then((_) {
      _transformationController.value = targetMatrix;
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildImageContent() {
    final path = widget.evidence.localFilePath;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF38BDF8),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildErrorPlaceholder();
      }
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 54,
          ),
          const SizedBox(height: 12),
          const Text(
            'Media tidak dapat dibuka',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'File media tidak tersedia pada perangkat.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggleControls,
      onDoubleTapDown: _handleDoubleTap,
      onDoubleTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: _isZoomed,
          scaleEnabled: true,
          child: _buildImageContent(),
        ),
      ),
    );
  }
}
