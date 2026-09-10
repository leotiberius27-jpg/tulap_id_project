import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_usage_entity.dart';
import '../utils/plan_visuals.dart';
import 'plan_folder_content.dart';
import 'plan_folder_shell.dart';

/// Ringkasan state siap-tampil satu folder - dihitung oleh
/// SubscriptionController dari satu sumber kebenaran (plan + subscription
/// + usage), supaya carousel tinggal merender tanpa logic bisnis
/// tersebar (Bagian 36 dokumen redesign).
class PlanCardViewModel {
  final PlanEntity plan;
  final bool isCurrentPlan;
  final SubscriptionUsageEntity? usage;
  final String ctaLabel;
  final bool isCtaEnabled;
  final bool isCtaLoading;

  const PlanCardViewModel({
    required this.plan,
    required this.isCurrentPlan,
    required this.usage,
    required this.ctaLabel,
    required this.isCtaEnabled,
    required this.isCtaLoading,
  });
}

/// PlanFolderCarousel
/// ----------------------------------------------------------------------
/// Carousel folder horizontal yang interaktif dan "hidup" (Bagian 6-19
/// dokumen redesign): drag real-time, scale/opacity/shadow interpolasi
/// kontinu, snap fisik via PageView native, tap-to-select folder yang
/// sedang peek, idle breathing sangat halus pada folder terpilih, dan
/// dukungan Reduced Motion penuh.
/// ----------------------------------------------------------------------
class PlanFolderCarousel extends StatefulWidget {
  final List<PlanEntity> plans;
  final int selectedIndex;
  final BillingCycle billingCycle;
  final PlanCardViewModel Function(PlanEntity plan) viewModelFor;
  final ValueChanged<int> onSettled;
  final ValueChanged<PlanEntity> onCtaPressed;
  final double height;

  const PlanFolderCarousel({
    super.key,
    required this.plans,
    required this.selectedIndex,
    required this.billingCycle,
    required this.viewModelFor,
    required this.onSettled,
    required this.onCtaPressed,
    required this.height,
  });

  @override
  State<PlanFolderCarousel> createState() => _PlanFolderCarouselState();
}

class _PlanFolderCarouselState extends State<PlanFolderCarousel> {
  static const double _viewportFraction = 0.84;

  late final PageController _pageController;
  int _committedIndex = 0;
  bool _isDragging = false;
  bool _hasShownDiscoveryHint = false;

  @override
  void initState() {
    super.initState();
    _committedIndex = widget.selectedIndex;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: widget.selectedIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowDiscoveryHint(),
    );
  }

  @override
  void didUpdateWidget(covariant PlanFolderCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ganti Bulanan/Tahunan TIDAK PERNAH menggeser carousel (Bagian 26) -
    // hanya sinkronkan jika perubahan index datang dari luar (mis. tap
    // "Lihat perbandingan" lalu memilih paket lain di sana).
    if (widget.selectedIndex != _committedIndex &&
        widget.selectedIndex != oldWidget.selectedIndex) {
      _committedIndex = widget.selectedIndex;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (_pageController.hasClients) {
        if (disableAnimations) {
          _pageController.jumpToPage(widget.selectedIndex);
        } else {
          _pageController.animateToPage(
            widget.selectedIndex,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowDiscoveryHint() async {
    // First-time swipe discovery (Bagian 17) - satu kali per sesi app,
    // tanpa mekanisme penyimpanan preferensi baru (disengaja sederhana
    // sesuai arahan dokumen redesign untuk tidak menambah kompleksitas
    // besar demi fitur kecil ini).
    if (_hasShownDiscoveryHint) return;
    if (!mounted || widget.plans.length < 2) return;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) return;
    _hasShownDiscoveryHint = true;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_pageController.hasClients || _isDragging) return;

    const nudge = 0.026; // ~10px pada viewportFraction 0.84
    await _pageController.animateTo(
      _pageController.offset +
          _pageController.position.viewportDimension * nudge,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
    if (!mounted || !_pageController.hasClients) return;
    await _pageController.animateTo(
      _pageController.offset -
          _pageController.position.viewportDimension * nudge,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _goToIndex(int index) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    HapticFeedback.selectionClick();
    if (disableAnimations) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            setState(() => _isDragging = true);
          } else if (notification is ScrollEndNotification) {
            setState(() => _isDragging = false);
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.plans.length,
          onPageChanged: (index) {
            if (_committedIndex == index) return;
            _committedIndex = index;
            HapticFeedback.selectionClick();
            widget.onSettled(index);
          },
          itemBuilder: (context, index) {
            final plan = widget.plans[index];
            // Dihitung SEKALI per pembangunan item (bukan per frame drag) -
            // lihat `child` param AnimatedBuilder di bawah untuk alasan
            // performa (Bagian 46 dokumen redesign).
            final viewModel = widget.viewModelFor(plan);
            final content = PlanFolderContent(
              plan: viewModel.plan,
              billingCycle: widget.billingCycle,
              isCurrentPlan: viewModel.isCurrentPlan,
              usage: viewModel.usage,
              ctaLabel: viewModel.ctaLabel,
              isCtaEnabled: viewModel.isCtaEnabled,
              isCtaLoading: viewModel.isCtaLoading,
              onCtaPressed: () => widget.onCtaPressed(plan),
            );

            return AnimatedBuilder(
              animation: _pageController,
              child: content,
              builder: (context, child) {
                double page;
                try {
                  page =
                      _pageController.page ?? widget.selectedIndex.toDouble();
                } catch (_) {
                  page = widget.selectedIndex.toDouble();
                }
                final delta = (page - index).clamp(-1.0, 1.0);
                final absDelta = delta.abs();

                final scale = disableAnimations
                    ? 1.0
                    : _lerp(1.0, 0.93, absDelta);
                final opacity = disableAnimations
                    ? 1.0
                    : _lerp(1.0, 0.86, absDelta);
                final elevation = disableAnimations
                    ? 4.0
                    : _lerp(16.0, 3.0, absDelta);
                final parallaxDx = disableAnimations ? 0.0 : delta * -6.0;
                final isCommittedSelected = index == _committedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: _BreathingPressableFolder(
                        plan: plan,
                        elevation: elevation,
                        lipSettle: isCommittedSelected ? 1.0 : 0.72,
                        sheetParallaxDx: parallaxDx,
                        isSelected: isCommittedSelected,
                        isDragging: _isDragging,
                        disableAnimations: disableAnimations,
                        onTap: isCommittedSelected
                            ? null
                            : () => _goToIndex(index),
                        content: child!,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// _BreathingPressableFolder
/// ----------------------------------------------------------------------
/// Menggabungkan tiga lapis motion pada satu folder (Bagian 8-9 dokumen
/// redesign): press feedback instan, idle breathing sangat halus saat
/// folder terpilih diam, dan tap-to-select. Skala carousel (drag) sudah
/// diterapkan di widget induk - widget ini HANYA menambah skala relatif
/// kecil di atasnya.
/// ----------------------------------------------------------------------
class _BreathingPressableFolder extends StatefulWidget {
  final PlanEntity plan;
  final double elevation;
  final double lipSettle;
  final double sheetParallaxDx;
  final bool isSelected;
  final bool isDragging;
  final bool disableAnimations;
  final VoidCallback? onTap;
  final Widget content;

  const _BreathingPressableFolder({
    required this.plan,
    required this.elevation,
    required this.lipSettle,
    required this.sheetParallaxDx,
    required this.isSelected,
    required this.isDragging,
    required this.disableAnimations,
    required this.onTap,
    required this.content,
  });

  @override
  State<_BreathingPressableFolder> createState() =>
      _BreathingPressableFolderState();
}

class _BreathingPressableFolderState extends State<_BreathingPressableFolder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _syncBreathing();
  }

  @override
  void didUpdateWidget(covariant _BreathingPressableFolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreathing();
  }

  void _syncBreathing() {
    final shouldBreathe =
        widget.isSelected &&
        !widget.isDragging &&
        !widget.disableAnimations &&
        !_isPressed;
    if (shouldBreathe && !_breathController.isAnimating) {
      _breathController.repeat(reverse: true);
    } else if (!shouldBreathe && _breathController.isAnimating) {
      _breathController.stop();
      _breathController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
    _syncBreathing();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final palette = PlanVisuals.paletteFor(widget.plan.code, colors);

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: _semanticsLabel(widget.plan),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _breathController,
            child: PlanFolderShell(
              plan: widget.plan,
              palette: palette,
              elevation: widget.elevation,
              lipSettle: widget.lipSettle,
              sheetParallaxDx: widget.sheetParallaxDx,
              sheetContent: widget.content,
            ),
            builder: (context, child) {
              final breathe = widget.disableAnimations
                  ? 1.0
                  : 1.0 + (math.sin(_breathController.value * math.pi) * 0.012);
              return Transform.scale(scale: breathe, child: child);
            },
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(PlanEntity plan) {
    final priceLabel = plan.isFree ? 'gratis' : 'berbayar';
    final popular = plan.badgeLabel != null ? ', ${plan.badgeLabel}' : '';
    final selected = widget.isSelected ? ', dipilih' : '';
    return '${plan.displayName}, ${plan.activityLimit} kegiatan per bulan, $priceLabel$popular$selected';
  }
}
