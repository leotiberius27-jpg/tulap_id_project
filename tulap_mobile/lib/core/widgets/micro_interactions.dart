import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// TapScale
/// ----------------------------------------------------------------------
/// Feedback tekan generik: child mengecil sedikit selagi ditekan lalu
/// kembali saat dilepas. Dipasang DI ATAS widget yang sudah punya ripple
/// sendiri (InkWell/OutlinedButton) - pakai `Listener`, bukan
/// `GestureDetector`, supaya tidak merebut gesture tap dari child.
/// ----------------------------------------------------------------------
class TapScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const TapScale({super.key, required this.child, this.scale = 0.95});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppMotion.micro,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// FloatingBob
/// ----------------------------------------------------------------------
/// Membuat child melayang naik-turun halus tanpa henti (translateY loop
/// kecil). Durasi berbeda-beda per instance supaya beberapa ikon yang
/// mengambang bersamaan tidak terlihat sinkron/kaku.
/// ----------------------------------------------------------------------
class FloatingBob extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;

  const FloatingBob({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2200),
    this.distance = 3,
  });

  @override
  State<FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = Curves.easeInOut.transform(_controller.value) * widget.distance;
        return Transform.translate(offset: Offset(0, -offset), child: child);
      },
      child: widget.child,
    );
  }
}

/// PulseDot
/// ----------------------------------------------------------------------
/// Titik status yang berdenyut pelan (opacity loop) - dipakai pada badge
/// "Online" supaya terasa hidup, bukan ikon statis.
/// ----------------------------------------------------------------------
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulseDot({super.key, required this.color, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 0.55 + (0.45 * t),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

/// Route dengan transisi slide-dari-kanan + fade, dipakai antar layar auth
/// (mis. Welcome -> Login) sebagai pengganti `MaterialPageRoute` polos.
Route<T> slideFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.screen,
    reverseTransitionDuration: AppMotion.screen,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
