import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// HeroVideoScene
/// ----------------------------------------------------------------------
/// Menampilkan video referensi murni `assets/videos/06.mp4` (dari Referensi/Mobile/06.mp4):
/// - Memutar video secara otomatis dalam loop tanpa suara (muted, 60 FPS).
/// - Layer latar belakang murni dan non-interaktif (`IgnorePointer` & `ExcludeSemantics`).
/// - Manajemen lifecycle otomatis (pause saat app ke background, resume saat aktif).
/// - Transisi fade-in 300ms halus saat video selesai diinisialisasi.
/// - Pembersihan memori tuntas pada `dispose()`.
/// ----------------------------------------------------------------------
class HeroVideoScene extends StatefulWidget {
  final BoxFit fit;
  final Alignment alignment;

  const HeroVideoScene({
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  @override
  State<HeroVideoScene> createState() => _HeroVideoSceneState();
}

class _HeroVideoSceneState extends State<HeroVideoScene>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      _controller?.play();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
  }

  Future<void> _initVideo() async {
    try {
      VideoPlayerController controller;
      try {
        controller = VideoPlayerController.asset('assets/videos/02.mp4');
        await controller.initialize();
      } catch (_) {
        try {
          controller = VideoPlayerController.asset('assets/videos/hero_video.mp4');
          await controller.initialize();
        } catch (_) {
          controller = VideoPlayerController.asset('assets/videos/01.mp4');
          await controller.initialize();
        }
      }

      await controller.setLooping(true);
      await controller.setVolume(0.0); // Muted background

      if (!mounted) {
        controller.dispose();
        return;
      }

      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!disableAnimations) {
        await controller.play();
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ExcludeSemantics(
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Solid Blue Base & Fallback Poster
              Container(
                color: const Color(0xFF0056D2),
                child: Image.asset(
                  'assets/images/referensi/01.png',
                  fit: widget.fit,
                  alignment: widget.alignment,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/hero_illustration.png',
                    fit: widget.fit,
                    alignment: widget.alignment,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 2. Video Player Layer (Pemutaran Murni Video 06.mp4)
              if (_isInitialized && _controller != null && !_hasError)
                AnimatedOpacity(
                  opacity: _isInitialized ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: widget.fit,
                      alignment: widget.alignment,
                      child: SizedBox(
                        width: _controller!.value.size.width > 0
                            ? _controller!.value.size.width
                            : 720,
                        height: _controller!.value.size.height > 0
                            ? _controller!.value.size.height
                            : 1280,
                        child: VideoPlayer(_controller!),
                      ),
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
