import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _taskListController = TaskListController(
      getActiveTasks: sl<GetActiveTasks>(),
      getCurrentSession: sl<GetCurrentSession>(),
    );
    _historyController = HistoryController(
      getActiveTasks: sl<GetActiveTasks>(),
      getCurrentSession: sl<GetCurrentSession>(),
    );
    _pages = [
      const HomePage(),
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
    _loadUser();
  }

  @override
  void dispose() {
    _taskListController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await sl<GetCurrentSession>()();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _onCameraPressed() async {
    if (_isResolvingTask) return;
    HapticFeedback.mediumImpact();
    setState(() => _isResolvingTask = true);

    final result = await sl<PickActiveTask>()();

    if (!mounted) return;
    setState(() => _isResolvingTask = false);

    result.fold(
      (failure) => _showMessage(failure.message),
      (task) {
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
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _CameraFab(
        isLoading: _isResolvingTask,
        onPressed: _onCameraPressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        currentIndex: _index,
        onTap: (i) {
          HapticFeedback.selectionClick();
          final isSwitchingTab = i != _index;
          setState(() => _index = i);
          if (!isSwitchingTab) return;
          if (i == 1) _taskListController.load();
          if (i == 2) _historyController.load();
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.surface,
      elevation: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Beranda',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'Tugas',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
              label: 'Riwayat',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Akun',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.stateChange,
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppMotion.stateChange,
              style: AppTypography.small.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _CameraFab({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Semantics(
          button: true,
          label: 'Ambil bukti tugas',
          enabled: !isLoading,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
