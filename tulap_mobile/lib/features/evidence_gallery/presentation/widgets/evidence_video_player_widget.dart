import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';

/// EvidenceVideoPlayerWidget
/// ----------------------------------------------------------------------
/// Komponen pemutar video bukti kegiatan lapangan dengan:
/// - Thumbnail/poster & tombol putar besar awal.
/// - Inisialisasi video player aman & hemat memori RAM.
/// - Kontrol play/pause, seekbar interaktif, dan format durasi `00:07 / 00:24`.
/// - Otomatis pause saat pengguna swipe ke media lain atau meninggalkan layar.
/// - Dukungan video dengan suara maupun video hening (silent video).
/// ----------------------------------------------------------------------
class EvidenceVideoPlayerWidget extends StatefulWidget {
  final GeotagPhotoEntity evidence;
  final bool isActive;
  final VoidCallback? onToggleControls;

  const EvidenceVideoPlayerWidget({
    super.key,
    required this.evidence,
    required this.isActive,
    this.onToggleControls,
  });

  @override
  State<EvidenceVideoPlayerWidget> createState() =>
      _EvidenceVideoPlayerWidgetState();
}

class _EvidenceVideoPlayerWidgetState extends State<EvidenceVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initVideoPlayer();
    }
  }

  @override
  void didUpdateWidget(covariant EvidenceVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      // Pause otomatis saat swiped away
      _controller?.pause();
      setState(() => _isPlaying = false);
    } else if (widget.isActive && !oldWidget.isActive) {
      if (_controller == null && !_hasError) {
        _initVideoPlayer();
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    final filePath = widget.evidence.localFilePath;
    try {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(filePath));
      } else if (filePath.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(filePath);
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          setState(() => _hasError = true);
          return;
        }
        _controller = VideoPlayerController.file(file);
      }

      try {
        await _controller!.initialize();
        if (!mounted) return;

        setState(() {
          _isInitialized = true;
          _totalDuration = _controller!.value.duration;
        });

        _controller!.addListener(_onControllerUpdate);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _totalDuration = Duration(seconds: widget.evidence.durationSeconds);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final position = value.position;

    if (isPlaying != _isPlaying ||
        position.inSeconds != _currentPosition.inSeconds) {
      setState(() {
        _isPlaying = isPlaying;
        _currentPosition = position;
        if (value.duration > Duration.zero) {
          _totalDuration = value.duration;
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) {
      _initVideoPlayer().then((_) {
        _controller?.play();
      });
      return;
    }

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _onSeek(double value) {
    if (_controller == null || !_isInitialized) return;
    final target = Duration(milliseconds: value.toInt());
    _controller!.seekTo(target);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white54,
              size: 54,
            ),
            const SizedBox(height: 12),
            const Text(
              'Video tidak dapat diputar',
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

    return GestureDetector(
      onTap: widget.onToggleControls,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AspectRatio(
          aspectRatio: _isInitialized && _controller!.value.aspectRatio > 0
              ? _controller!.value.aspectRatio
              : 9 / 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isInitialized && _controller != null)
                VideoPlayer(_controller!)
              else
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),

              // Overlay tombol play besar jika sedang pause
              if (!_isPlaying)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.65),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),

              // Bar kontrol video di bagian bawah video player
              if (_isInitialized)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Tombol Play/Pause kecil
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Elapsed Time
                        Text(
                          _formatDuration(_currentPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Seek Slider
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF006EE6),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              min: 0.0,
                              max: _totalDuration.inMilliseconds > 0
                                  ? _totalDuration.inMilliseconds.toDouble()
                                  : 1.0,
                              value: _currentPosition.inMilliseconds
                                  .clamp(0, _totalDuration.inMilliseconds)
                                  .toDouble(),
                              onChanged: _onSeek,
                            ),
                          ),
                        ),

                        // Total Duration
                        Text(
                          _formatDuration(_totalDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
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
}
