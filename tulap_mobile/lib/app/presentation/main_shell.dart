import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/session/auth_session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/auth/domain/entities/auth_user_entity.dart';
import '../../features/auth/domain/usecases/get_current_session.dart';
import '../../features/geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../features/history/presentation/controllers/history_controller.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/task_detail/domain/usecases/get_active_tasks.dart';
import '../../features/task_detail/domain/usecases/pick_active_task.dart';
import '../../features/task_list/presentation/controllers/task_list_controller.dart';
import '../../features/task_list/presentation/pages/task_list_page.dart';
import '../../features/travel_mission/domain/repositories/travel_repository.dart';
import '../../features/travel_mission/presentation/controllers/travel_mission_detail_controller.dart';
import '../../features/travel_mission/presentation/controllers/travel_mission_list_controller.dart';
import '../di/injection_container.dart';

/// MainShell
/// ----------------------------------------------------------------------
/// Bottom navigation utama pasca-login (Bagian 47 master prompt):
/// Beranda / Tugas / [tombol kamera tengah] / Riwayat / Akun. Setiap
/// tab dipertahankan hidup lewat `IndexedStack` (state controller-nya
/// tidak dibuang saat pindah tab, sesuai Bagian 19 - hindari rebuild
/// mahal berulang).
///
/// Tombol kamera tengah TIDAK menduplikasi logika pemilihan tugas
/// aktif Beranda - keduanya memakai `PickActiveTask` yang sama (lihat
/// domain usecase itu) agar aturan prioritas tugas satu sumber
/// kebenaran.
///
/// `TaskListController`/`HistoryController` sengaja dibuat & dipegang
/// DI SINI (bukan di dalam TaskListPage/HistoryPage sendiri seperti
/// sebelumnya) - karena `IndexedStack` memuat setiap tab hanya SEKALI
/// seumur hidup widget-nya, `load()` bawaan constructor cuma jalan
/// sekali di awal. Tanpa ini, tab Tugas/Riwayat tidak akan pernah
/// menunjukkan perubahan status yang terjadi dari sisi lain (mis.
/// Verifikator approve lewat web dashboard) sampai app di-restart -
/// ditemukan nyata saat uji coba live, bukan cuma dugaan. Fix-nya:
/// panggil ulang `.load()` tiap kali tab itu DIPILIH (bukan tiap
/// rebuild - itu akan sia-sia mem-flash spinner tiap switch tab yang
/// sama berulang).
/// ----------------------------------------------------------------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  AuthUserEntity? _user;
  bool _isResolvingTask = false;

  late final TaskListController _taskListController;
  late final HistoryController _historyController;
  late final AuthSessionManager _authSessionManager;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _authSessionManager = sl<AuthSessionManager>();
    _taskListController = TaskListController(
      getActiveTasks: sl<GetActiveTasks>(),
      getCurrentSession: sl<GetCurrentSession>(),
    );
    _historyController = HistoryController(
      getActiveTasks: sl<GetActiveTasks>(),
      getCurrentSession: sl<GetCurrentSession>(),
    );
    _pages = [
      HomePage(onNavigateToTab: _onTabSelected),
      ChangeNotifierProvider<TaskListController>.value(
        value: _taskListController,
        child: const TaskListPage(),
      ),
      ChangeNotifierProvider<HistoryController>.value(
        value: _historyController,
        child: const HistoryPage(),
      ),
      const AccountPage(),
    ];
    _user = _authSessionManager.currentUser;
    _authSessionManager.addListener(_onUserSessionChanged);
    _loadUser();
  }

  void _onTabSelected(int i) {
    HapticFeedback.selectionClick();
    final isSwitchingTab = i != _index;
    setState(() => _index = i);
    if (!isSwitchingTab) return;
    if (i == 0 || i == 3) _loadUser();
    if (i == 1) _taskListController.load();
    if (i == 2) _historyController.load();
  }

  void _onUserSessionChanged() {
    if (mounted) {
      setState(() => _user = _authSessionManager.currentUser);
    }
  }

  @override
  void dispose() {
    _authSessionManager.removeListener(_onUserSessionChanged);
    _taskListController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = _authSessionManager.currentUser ?? await sl<GetCurrentSession>()();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _onCameraPressed() async {
    if (_isResolvingTask) return;
    HapticFeedback.mediumImpact();
    setState(() => _isResolvingTask = true);

    final result = await sl<PickActiveTask>()();

    if (!mounted) return;
    setState(() => _isResolvingTask = false);

    result.fold((failure) => _showMessage(failure.message), (task) {
      if (task == null) {
        _showMessage('Belum ada tugas aktif untuk diambil buktinya.');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GeotagCameraEntryPage(
            officerName: _user?.fullName ?? 'Pengguna',
            agencyName: _user?.instansiName ?? 'Instansi tidak diketahui',
            taskId: task.id,
          ),
        ),
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TravelRepository>.value(value: sl<TravelRepository>()),
        ChangeNotifierProvider<TravelMissionListController>(
          create: (_) => sl<TravelMissionListController>(),
        ),
        ChangeNotifierProvider<TravelMissionDetailController>(
          create: (_) => sl<TravelMissionDetailController>(),
        ),
      ],
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        floatingActionButton: TulapAnimatedCameraFab(
          isLoading: _isResolvingTask,
          onPressed: _onCameraPressed,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: TulapAnimatedBottomBar(
          currentIndex: _index,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}

/// TulapAnimatedBottomBar
/// ----------------------------------------------------------------------
/// Fluid curved-notch animated bottom navigation bar (sesuai referensi Navigasi.gif):
/// - 4 tab utama (Beranda, Tugas, Riwayat, Akun) menggunakan transisi lengkungan
///   fluid organic wave notch dan elevated floating circular active button.
/// - Slot tengah menyediakan ruang khusus untuk tombol Camera FAB utama.
/// ----------------------------------------------------------------------
class TulapAnimatedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TulapAnimatedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navItems = [
      (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.tabHome),
      (icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: l10n.tabTasks),
      (icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: l10n.tabHistory),
      (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: l10n.tabAccount),
    ];

    final mediaQuery = MediaQuery.of(context);
    final disableAnimations = mediaQuery.disableAnimations;
    final animDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 280);
    const animCurve = Curves.easeOutCubic;

    final bottomPadding = mediaQuery.padding.bottom;
    const barHeight = 64.0;

    final colors = context.tulapColors;

    return SizedBox(
      height: barHeight + bottomPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // 5 slots: [0: Beranda] [1: Tugas] [2: Center Camera Spacer] [3: Riwayat] [4: Akun]
          final slotWidth = totalWidth / 5.0;

          // Mapping tab index -> slot index:
          // Tab 0 -> Slot 0 (Beranda)
          // Tab 1 -> Slot 1 (Tugas)
          // Tab 2 -> Slot 3 (Riwayat)
          // Tab 3 -> Slot 4 (Akun)
          final activeSlotIndex =
              currentIndex < 2 ? currentIndex : currentIndex + 1;
          final targetCenterX = slotWidth * (activeSlotIndex + 0.5);
          final activeIcon = navItems[currentIndex].activeIcon;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: targetCenterX, end: targetCenterX),
            duration: animDuration,
            curve: animCurve,
            builder: (context, currentCenterX, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Fluid Curved Notch Canvas Background for the active tab
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CurvedNotchPainter(
                        centerX: currentCenterX,
                        color: colors.surface,
                        shadowColor: colors.shadowSoft,
                      ),
                    ),
                  ),

                  // 2. Floating Elevated Circular Active Tab Button (in Notch Cradle)
                  Positioned(
                    left: currentCenterX - 26.0,
                    top: -14.0,
                    child: IgnorePointer(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              activeIcon,
                              key: ValueKey(activeIcon),
                              color: colors.primary,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Tab Buttons Row
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: barHeight,
                    child: Row(
                      children: [
                        // Slot 0: Beranda / Home
                        Expanded(
                          child: _CurvedNavItem(
                            icon: navItems[0].icon,
                            activeIcon: navItems[0].activeIcon,
                            label: navItems[0].label,
                            isActive: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                        ),

                        // Slot 1: Tugas / Tasks
                        Expanded(
                          child: _CurvedNavItem(
                            icon: navItems[1].icon,
                            activeIcon: navItems[1].activeIcon,
                            label: navItems[1].label,
                            isActive: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                        ),

                        // Slot 2: Center Spacer for Prominent Camera FAB
                        SizedBox(width: slotWidth),

                        // Slot 3: Riwayat / History
                        Expanded(
                          child: _CurvedNavItem(
                            icon: navItems[2].icon,
                            activeIcon: navItems[2].activeIcon,
                            label: navItems[2].label,
                            isActive: currentIndex == 2,
                            onTap: () => onTap(2),
                          ),
                        ),

                        // Slot 4: Akun / Account
                        Expanded(
                          child: _CurvedNavItem(
                            icon: navItems[3].icon,
                            activeIcon: navItems[3].activeIcon,
                            label: navItems[3].label,
                            isActive: currentIndex == 3,
                            onTap: () => onTap(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// _CurvedNavItem
/// ----------------------------------------------------------------------
/// Item navigasi individual di dalam bar lengkung.
/// ----------------------------------------------------------------------
class _CurvedNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CurvedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final inactiveColor = colors.textSecondary;
    final activeColor = colors.primary;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      container: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: colors.primary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Inactive icon placeholder (hidden when active because elevated circle appears in the notch)
                if (!isActive)
                  Icon(
                    icon,
                    size: 22,
                    color: inactiveColor,
                  )
                else
                  const SizedBox(height: 22),
                SizedBox(height: isActive ? 12 : 3),
                // Label
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                      letterSpacing: -0.1,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TulapAnimatedCameraFab
/// ----------------------------------------------------------------------
/// Center prominent camera action button dengan micro-interaction press scale
/// dan Tulap.id blue gradient.
/// ----------------------------------------------------------------------
class TulapAnimatedCameraFab extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const TulapAnimatedCameraFab({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<TulapAnimatedCameraFab> createState() => _TulapAnimatedCameraFabState();
}

class _TulapAnimatedCameraFabState extends State<TulapAnimatedCameraFab> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka Kamera Geotag Lapangan',
      container: true,
      enabled: !widget.isLoading,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : 1.00,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A84E8), // Active accent blue top
                  Color(0xFF00529C), // Primary navy bottom
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: _isPressed ? 0.22 : 0.38,
                  ),
                  blurRadius: _isPressed ? 10 : 16,
                  offset: Offset(0, _isPressed ? 2 : 5),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CurvedNotchPainter
/// ----------------------------------------------------------------------
/// CustomPainter yang menggambar lengkungan halus (wave notch dip) di atas bar
/// putih, persis sesuai referensi Navigasi.gif.
/// ----------------------------------------------------------------------
class CurvedNotchPainter extends CustomPainter {
  final double centerX;
  final Color color;
  final Color shadowColor;

  CurvedNotchPainter({
    required this.centerX,
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double dipRadius = 36.0; // Setengah lebar kurva
    const double dipDepth = 30.0;  // Kedalaman lengkungan

    final p0 = Offset(centerX - dipRadius * 1.5, 0);
    final p1 = Offset(centerX - dipRadius * 0.9, 0);
    final p2 = Offset(centerX - dipRadius * 0.6, dipDepth);
    final p3 = Offset(centerX, dipDepth);
    final p4 = Offset(centerX + dipRadius * 0.6, dipDepth);
    final p5 = Offset(centerX + dipRadius * 0.9, 0);
    final p6 = Offset(centerX + dipRadius * 1.5, 0);

    path.moveTo(0, 0);
    path.lineTo(p0.dx, 0);
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    path.cubicTo(p4.dx, p4.dy, p5.dx, p5.dy, p6.dx, p6.dy);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Gambar bayangan halus di atas dock
    canvas.drawShadow(path, shadowColor, 8.0, true);

    // Gambar isi dock
    canvas.drawPath(path, paint);

    // Garis border atas yang sangat halus
    final borderPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(p0.dx, 0);
    topPath.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    topPath.cubicTo(p4.dx, p4.dy, p5.dx, p5.dy, p6.dx, p6.dy);
    topPath.lineTo(size.width, 0);
    canvas.drawPath(topPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor;
  }
}
