import 'package:flutter/material.dart';
import '../controllers/tula_visibility_controller.dart';

/// TulaFloatingButton
/// ----------------------------------------------------------------------
/// Identitas visual Tula: squircle 56x56 gradient Deep Navy -> Action
/// Blue, ikon "spark" (bukan robot) berwarna putih.
///
/// Widget ini murni visual - state tekan/drag dikendalikan dari LUAR
/// (TulaOverlay, yang memegang satu GestureDetector pan untuk membedakan
/// tap vs drag, lihat Bagian 5 spesifikasi upgrade Tula draggable).
/// Animasi "hidup" yang berjalan sendiri di sini hanyalah:
/// - breathing halus saat idle (berhenti otomatis saat ditekan/drag atau
///   reduced motion aktif),
/// - pulse SEKALI saat insight baru muncul.
/// ----------------------------------------------------------------------
class TulaFloatingButton extends StatefulWidget {
  final bool hasInsight;
  final TulaInsightSeverity? insightSeverity;
  final bool isOnline;
  final bool isLoading;
  final bool enabled;

  /// true selagi jari masih menyentuh (tap ATAU awal drag).
  final bool isPressed;

  /// true setelah movement melewati drag threshold.
  final bool isDragging;

  const TulaFloatingButton({
    super.key,
    required this.hasInsight,
    required this.insightSeverity,
    required this.isOnline,
    this.isLoading = false,
    this.enabled = true,
    this.isPressed = false,
    this.isDragging = false,
  });

  @override
  State<TulaFloatingButton> createState() => _TulaFloatingButtonState();
}

class _TulaFloatingButtonState extends State<TulaFloatingButton>
    with TickerProviderStateMixin {
  static const _navy = Color(0xFF00529C);
  static const _actionBlue = Color(0xFF0072CE);
  static const _warning = Color(0xFFF59E0B);

  late final AnimationController _pulseController;
  late final AnimationController _breathingController;
  bool _pulsedForCurrentInsight = false;

  bool get _reduceMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _pulsedForCurrentInsight = !widget.hasInsight;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBreathing());
  }

  void _syncBreathing() {
    if (!mounted) return;
    final shouldBreathe =
        !widget.isPressed && !widget.isDragging && !_reduceMotion;
    if (shouldBreathe) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
    } else {
      if (_breathingController.isAnimating) _breathingController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant TulaFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasInsight && !oldWidget.hasInsight) {
      _pulsedForCurrentInsight = false;
    }
    if (!widget.hasInsight) {
      _pulsedForCurrentInsight = false;
    } else if (!_pulsedForCurrentInsight) {
      _pulsedForCurrentInsight = true;
      if (!_reduceMotion) _pulseController.forward(from: 0);
    }
    _syncBreathing();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        widget.insightSeverity == TulaInsightSeverity.warning ? _warning : _actionBlue;
    final reduceMotion = _reduceMotion;

    final pressScale = widget.isDragging ? 1.06 : (widget.isPressed ? 0.95 : 1.0);

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _actionBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: widget.isDragging ? 0.34 : 0.22),
            blurRadius: widget.isDragging ? 30 : 24,
            offset: Offset(0, widget.isDragging ? 10 : 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 26,
                ),

          if (!widget.isOnline)
            Positioned(
              bottom: -3,
              right: -3,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _navy, width: 1.5),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 9,
                  color: Color(0xFF64748B),
                ),
              ),
            ),

          if (widget.hasInsight)
            Positioned(
              top: -2,
              right: -2,
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 2.0)
                      .chain(CurveTween(curve: Curves.easeOut))
                      .animate(_pulseController),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.55, end: 0.0).animate(_pulseController),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ),

          if (widget.hasInsight)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );

    // Breathing: skala sangat halus 1.00 -> 1.025 -> 1.00, berhenti saat
    // ditekan/drag atau reduced motion (Bagian 6 & 27).
    if (!reduceMotion) {
      button = AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathe = 1.0 + (_breathingController.value * 0.025);
          return Transform.scale(scale: breathe, child: child);
        },
        child: button,
      );
    }

    // Press/drag scale bereaksi cepat (motion.fast) di luar breathing.
    button = AnimatedScale(
      scale: pressScale,
      duration: const Duration(milliseconds: _pressScaleDurationMs),
      curve: Curves.easeOut,
      child: button,
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: _semanticLabel(),
      child: button,
    );
  }

  static const int _pressScaleDurationMs = 140;

  String _semanticLabel() {
    if (!widget.isOnline) return 'Buka Tula, Asisten Tulap.id. Sedang offline.';
    if (widget.hasInsight) {
      return 'Buka Tula, Asisten Tulap.id. 1 hal perlu diperhatikan.';
    }
    return 'Buka Tula, Asisten Tulap.id';
  }
}
