import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../search_archive/domain/entities/search_filter_state.dart';
import '../../../search_archive/domain/entities/search_result_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_list/presentation/controllers/task_list_controller.dart';
import '../../../task_list/presentation/pages/task_list_page.dart';
import '../controllers/tula_visibility_controller.dart';
import 'tula_bottom_sheet.dart';
import 'tula_floating_button.dart';
import 'tula_insight_bubble.dart';

/// _Bounds
/// ----------------------------------------------------------------------
/// Area aman tempat Tula boleh berada, dihitung ulang tiap build dari
/// MediaQuery saat ini (rotasi/resize otomatis aman - Bagian 3 & 21).
/// ----------------------------------------------------------------------
class _Bounds {
  final double leftMin;
  final double leftMax;
  final double topMin;
  final double topMax;
  final double rightRestLeft;

  const _Bounds({
    required this.leftMin,
    required this.leftMax,
    required this.topMin,
    required this.topMax,
    required this.rightRestLeft,
  });
}

/// TulaOverlay
/// ----------------------------------------------------------------------
/// Satu-satunya tempat TulaFloatingButton pernah dirender - dipasang di
/// `builder` MaterialApp (lihat main.dart) sehingga berlaku untuk SELURUH
/// Navigator tanpa duplikasi di nested navigator manapun.
///
/// Memegang seluruh mekanik "hidup" Tula: draggable + magnetic edge
/// snap, breathing/idle, peek mode, insight bubble, dan long-press quick
/// menu - semuanya di satu State supaya gesture (pan vs tap vs
/// long-press) tidak saling konflik antar widget terpisah.
/// ----------------------------------------------------------------------
class TulaOverlay extends StatefulWidget {
  final Widget child;

  const TulaOverlay({super.key, required this.child});

  /// TulaOverlay dipasang lewat `builder` MaterialApp - context BAWAAN
  /// widget itu sendiri ada DI LUAR Navigator (Navigator dibuat di dalam
  /// `widget.child`), jadi `Navigator.of(context)` dari State.build tidak
  /// pernah menemukan Navigator. Pasang GlobalKey ini ke
  /// `MaterialApp(navigatorKey: ...)` di main.dart supaya TulaOverlay
  /// selalu punya context yang valid untuk membuka bottom sheet/route.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<TulaOverlay> createState() => _TulaOverlayState();
}

class _TulaOverlayState extends State<TulaOverlay> {
  static const double _buttonSize = 56.0;
  static const double _edgeMargin = 20.0;
  static const double _peekHiddenFraction = 0.62;
  static const Duration _idleDelay = Duration(seconds: 10);
  static const Duration _snapDuration = Duration(milliseconds: 220);
  static const Duration _bubbleDuration = Duration(seconds: 4);

  late final TulaVisibilityController _tula;
  late final AuthSessionManager _authSessionManager;

  double? _left;
  double? _top;
  bool _isPointerDown = false;
  bool _isDragging = false;
  bool _isPeeked = false;

  String? _shownInsightKey;
  String? _activeBubbleMessage;
  Timer? _bubbleTimer;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _tula = sl<TulaVisibilityController>();
    _authSessionManager = sl<AuthSessionManager>();
    _tula.addListener(_onChanged);
    _authSessionManager.addListener(_onChanged);
    _resetIdleTimer();
  }

  void _onChanged() {
    // Notifikasi bisa datang SAAT frame lain sedang membangun widget tree
    // (mis. AuthSessionManager.notifyListeners() dipicu dari initState
    // AuthGate ketika TulaOverlay masih menginflate child-nya) - memanggil
    // setState langsung di situasi itu memicu "setState() called during
    // build". Tunda ke akhir frame supaya selalu aman.
    if (!mounted) return;

    final key = _tula.hasInsight ? _tula.insightMessage : null;
    if (key != null && key != _shownInsightKey) {
      _shownInsightKey = key;
      _activeBubbleMessage = key;
      _bubbleTimer?.cancel();
      _bubbleTimer = Timer(_bubbleDuration, () {
        if (mounted) setState(() => _activeBubbleMessage = null);
      });
    }
    if (!_tula.hasInsight) _shownInsightKey = null;
    if (_tula.isInsightCritical && _isPeeked) _isPeeked = false;

    _resetIdleTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_tula.isSuppressed || _tula.isSheetOpen || _tula.isTemporarilyHidden) {
      return;
    }
    _idleTimer = Timer(_idleDelay, () {
      if (!mounted) return;
      if (_isPointerDown ||
          _isDragging ||
          _tula.isSheetOpen ||
          _tula.isInsightCritical ||
          _activeBubbleMessage != null) {
        return;
      }
      setState(() => _isPeeked = true);
    });
  }

  @override
  void dispose() {
    _tula.removeListener(_onChanged);
    _authSessionManager.removeListener(_onChanged);
    _bubbleTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  _Bounds _computeBounds(BuildContext context, TulaContextData current) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final topMin = mq.padding.top + 84.0;
    final minBottomOffset =
        mq.padding.bottom + (current.hasBottomNav ? 88.0 : 24.0);
    var topMax = size.height - minBottomOffset - _buttonSize;
    if (topMax < topMin) topMax = topMin;
    return _Bounds(
      leftMin: 8.0,
      leftMax: (size.width - _buttonSize - 8.0).clamp(8.0, double.infinity),
      topMin: topMin,
      topMax: topMax,
      rightRestLeft: size.width - _buttonSize - _edgeMargin,
    );
  }

  Offset _restOffset(_Bounds b, TulaPosition pos, bool peeked) {
    final top = b.topMin + pos.verticalRatio * (b.topMax - b.topMin);
    double left;
    if (pos.isLeft) {
      left = _edgeMargin;
      if (peeked) left -= _buttonSize * _peekHiddenFraction;
    } else {
      left = b.rightRestLeft;
      if (peeked) left += _buttonSize * _peekHiddenFraction;
    }
    return Offset(left, top);
  }

  void _onPanDown(DragDownDetails details, Offset seed) {
    _idleTimer?.cancel();
    setState(() {
      _isPointerDown = true;
      _isDragging = false;
      _left = seed.dx;
      _top = seed.dy;
    });
  }

  /// `onPanUpdate` di GestureDetector HANYA pernah dipanggil Flutter
  /// setelah PanGestureRecognizer benar-benar memenangkan gesture arena
  /// (yaitu movement sudah melewati touch slop bawaan framework) - jadi
  /// begitu callback ini terpanggil, gestur SUDAH PASTI drag, bukan tap.
  /// Ini menghindari bug tap-diam yang tidak pernah memicu onPanEnd
  /// karena PanGestureRecognizer tidak pernah "start" untuk gestur tanpa
  /// pergerakan (lihat Bagian 5 - tap vs drag).
  void _onPanUpdate(DragUpdateDetails details, _Bounds bounds) {
    if (_left == null || _top == null) return;
    setState(() {
      _left = (_left! + details.delta.dx).clamp(bounds.leftMin, bounds.leftMax);
      _top = (_top! + details.delta.dy).clamp(bounds.topMin, bounds.topMax);
      if (!_isDragging) {
        _isDragging = true;
        HapticFeedback.selectionClick();
      }
    });
  }

  void _onPanEnd(DragEndDetails details, _Bounds bounds, double screenWidth) {
    if (_left == null || _top == null || !_isDragging) {
      setState(() {
        _isPointerDown = false;
        _isDragging = false;
        _left = null;
        _top = null;
      });
      _resetIdleTimer();
      return;
    }

    final centerX = _left! + _buttonSize / 2;
    final newIsLeft = centerX < screenWidth / 2;
    final ratio = bounds.topMax > bounds.topMin
        ? ((_top! - bounds.topMin) / (bounds.topMax - bounds.topMin)).clamp(0.0, 1.0)
        : 0.0;

    setState(() {
      _isPointerDown = false;
      _isDragging = false;
      _left = null;
      _top = null;
    });
    _tula.updatePosition(TulaPosition(isLeft: newIsLeft, verticalRatio: ratio));
    HapticFeedback.selectionClick();
    _resetIdleTimer();
  }

  /// Dipanggil Flutter saat PanGestureRecognizer KALAH di gesture arena
  /// (mis. tap diam dimenangkan oleh TapGestureRecognizer via [_onTap]) -
  /// cukup bersihkan state visual "ditekan", TANPA membuka sheet di sini
  /// (itu tugas [_onTap]) supaya tidak terpicu dua kali untuk satu tap.
  void _onPanCancel() {
    setState(() {
      _isPointerDown = false;
      _isDragging = false;
      _left = null;
      _top = null;
    });
    _resetIdleTimer();
  }

  /// Tap murni (nyaris tanpa pergerakan) ditangani TapGestureRecognizer
  /// terpisah dari Pan, supaya selalu terpicu dengan andal (lihat catatan
  /// di [_onPanUpdate]).
  void _onTap() {
    final wasPeeked = _isPeeked;
    setState(() {
      _isPointerDown = false;
      _isDragging = false;
      _left = null;
      _top = null;
      if (wasPeeked) _isPeeked = false;
    });
    _resetIdleTimer();
    if (wasPeeked) return; // tap pada Tula yang peek hanya membuka penuh
    HapticFeedback.lightImpact();
    _dismissBubble();
    _openSheet();
  }

  void _dismissBubble() {
    _bubbleTimer?.cancel();
    if (_activeBubbleMessage == null) return;
    setState(() => _activeBubbleMessage = null);
  }

  void _openSheet() {
    final navContext = TulaOverlay.navigatorKey.currentContext;
    if (navContext != null) TulaBottomSheet.show(navContext);
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    final navContext = TulaOverlay.navigatorKey.currentContext;
    if (navContext == null) return;
    HapticFeedback.mediumImpact();
    _idleTimer?.cancel();

    final overlayBox =
        Overlay.of(navContext).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlayBox.size,
    );
    final isLeft = _tula.position.isLeft;

    final selected = await showMenu<String>(
      context: navContext,
      position: position,
      items: [
        const PopupMenuItem(value: 'ask', child: Text('Tanya Tula')),
        const PopupMenuItem(value: 'tasks', child: Text('Cek Tugas')),
        const PopupMenuItem(value: 'evidence', child: Text('Cek Bukti')),
        PopupMenuItem(
          value: 'move',
          child: Text(isLeft ? 'Pindah ke Kanan' : 'Pindah ke Kiri'),
        ),
        const PopupMenuItem(value: 'hide', child: Text('Sembunyikan sementara')),
      ],
    );

    if (!mounted) return;
    setState(() {
      _isPointerDown = false;
      _isDragging = false;
      _left = null;
      _top = null;
    });
    _resetIdleTimer();

    final freshNavContext = TulaOverlay.navigatorKey.currentContext;
    switch (selected) {
      case 'ask':
        _openSheet();
        break;
      case 'tasks':
        if (freshNavContext != null) _openTaskList(freshNavContext);
        break;
      case 'evidence':
        if (freshNavContext != null) _openEvidenceHistory(freshNavContext);
        break;
      case 'move':
        _tula.updatePosition(
          TulaPosition(isLeft: !isLeft, verticalRatio: _tula.position.verticalRatio),
        );
        break;
      case 'hide':
        _tula.hideTemporarily();
        break;
    }
  }

  void _openTaskList(BuildContext navContext) {
    Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskListController>(
          create: (_) => TaskListController(
            getActiveTasks: sl<GetActiveTasks>(),
            getCurrentSession: sl<GetCurrentSession>(),
          ),
          child: const TaskListPage(),
        ),
      ),
    );
  }

  void _openEvidenceHistory(BuildContext navContext) {
    Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => const HistoryPage(
          initialFilter: SearchFilterState(selectedType: SearchEntityType.evidence),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLoggedIn = _authSessionManager.currentUser != null;
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final current = _tula.current;

    final fullyHidden = !isLoggedIn ||
        _tula.isSuppressed ||
        _tula.isSheetOpen ||
        keyboardOpen ||
        !_tula.positionLoaded;

    final showTab = !fullyHidden && _tula.isTemporarilyHidden;
    final showButton = !fullyHidden && !_tula.isTemporarilyHidden;

    final overlayChildren = <Widget>[widget.child];

    if (showButton) {
      final bounds = _computeBounds(context, current);
      final effectivePeek = _isPeeked && !_tula.isInsightCritical;
      final restOffset = _restOffset(bounds, _tula.position, effectivePeek);
      final left = _left ?? restOffset.dx;
      final top = _top ?? restOffset.dy;
      final duration = _isPointerDown ? Duration.zero : _snapDuration;
      final isLeft = _tula.position.isLeft;

      overlayChildren.add(
        AnimatedPositioned(
          duration: duration,
          curve: Curves.easeOutCubic,
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            onPanDown: (d) => _onPanDown(d, Offset(left, top)),
            onPanUpdate: (d) => _onPanUpdate(d, bounds),
            onPanEnd: (d) => _onPanEnd(d, bounds, mediaQuery.size.width),
            onPanCancel: _onPanCancel,
            onLongPressStart: _handleLongPressStart,
            child: TulaFloatingButton(
              hasInsight: _tula.hasInsight,
              insightSeverity: _tula.insightSeverity,
              isOnline: _tula.isOnline,
              isPressed: _isPointerDown,
              isDragging: _isDragging,
            ),
          ),
        ),
      );

      if (_activeBubbleMessage != null && !_isDragging) {
        final bubbleTop = (top - 58.0).clamp(mediaQuery.padding.top + 8.0, top);
        overlayChildren.add(
          Positioned(
            top: bubbleTop,
            left: isLeft ? left : null,
            right: isLeft ? null : (mediaQuery.size.width - left - _buttonSize),
            child: TulaInsightBubble(
              message: _activeBubbleMessage!,
              anchorLeft: isLeft,
              onTap: () {
                _dismissBubble();
                _openSheet();
              },
            ),
          ),
        );
      }
    } else if (showTab) {
      final bounds = _computeBounds(context, current);
      final restOffset = _restOffset(bounds, _tula.position, false);
      final isLeft = _tula.position.isLeft;
      overlayChildren.add(
        AnimatedPositioned(
          duration: _snapDuration,
          curve: Curves.easeOutCubic,
          left: isLeft ? 0 : null,
          right: isLeft ? null : 0,
          top: restOffset.dy + 8,
          child: Semantics(
            button: true,
            label: 'Tampilkan kembali Tula, Asisten Tulap.id',
            child: InkWell(
              onTap: () {
                _tula.unhide();
                _resetIdleTimer();
              },
              borderRadius: BorderRadius.horizontal(
                left: isLeft ? Radius.zero : const Radius.circular(10),
                right: isLeft ? const Radius.circular(10) : Radius.zero,
              ),
              child: Container(
                width: 18,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00529C),
                  borderRadius: BorderRadius.horizontal(
                    left: isLeft ? Radius.zero : const Radius.circular(10),
                    right: isLeft ? const Radius.circular(10) : Radius.zero,
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: overlayChildren);
  }
}
