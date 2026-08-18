import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../sync_queue/presentation/controllers/sync_center_controller.dart';
import '../../../sync_queue/presentation/pages/sync_center_page.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/active_task_card.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/sync_status_banner.dart';

/// HomePage (Beranda)
/// ----------------------------------------------------------------------
/// Layar Beranda sesuai Bagian 11.1 spesifikasi - titik tujuan setelah
/// Login berhasil (Bagian 8 Mobile Sitemap: `Login -> Beranda`).
/// Membungkus Provider-nya sendiri seperti LoginPage, karena
/// HomeController tidak butuh resource async (CameraController) yang
/// mengharuskan entry page terpisah.
/// ----------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeController>(
      create: (_) => HomeController(
        getCurrentSession: sl<GetCurrentSession>(),
        getActiveTasks: sl<GetActiveTasks>(),
        getTaskDetail: sl<GetTaskDetail>(),
        syncQueueRepository: sl<SyncQueueRepository>(),
        networkInfo: sl<NetworkInfo>(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          // Padding bawah tetap (BUKAN cuma spacer di dalam ListView) agar
          // tombol kamera tengah (FAB centerDocked di MainShell) tidak
          // menutupi konten terakhir - ini mengecilkan viewport ListView
          // itu sendiri, beda dengan padding di dalam scrollable yang
          // hanya menambah area scroll dan tidak menggeser konten yang
          // sudah muat tanpa scroll.
          child: Padding(
            padding: const EdgeInsets.only(bottom: 56),
            child: Consumer<HomeController>(
            builder: (context, controller, _) {
              final state = controller.state;

              if (state.status == HomeStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final officerName = state.user?.fullName ?? 'Pengguna';
              final agencyName =
                  state.user?.instansiName ?? 'Instansi tidak diketahui';
              final activeTask = state.activeTask;

              return RefreshIndicator(
                onRefresh: controller.loadHome,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    HomeHeader(
                      fullName: officerName,
                      agencyName: agencyName,
                      onNotificationTap: () =>
                          _showNotAvailable(context, 'Notifikasi'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Tugas Aktif',
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          activeTask != null
                              ? ActiveTaskCard(
                                  task: activeTask,
                                  onContinue: () => _openTaskDetail(
                                    context,
                                    taskId: activeTask.id,
                                    officerName: officerName,
                                    agencyName: agencyName,
                                  ),
                                )
                              : _buildEmptyTaskState(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Aksi Cepat',
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          QuickActionGrid(
                            onFotoKegiatan: activeTask == null
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => GeotagCameraEntryPage(
                                        officerName: officerName,
                                        agencyName: agencyName,
                                        taskId: activeTask.id,
                                      ),
                                    ),
                                  ),
                            onScanNota: activeTask == null
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReceiptScannerEntryPage(
                                        taskId: activeTask.id,
                                      ),
                                    ),
                                  ),
                            onLokasi: () =>
                                _showNotAvailable(context, 'Peta lokasi'),
                            onLihatLpj: () =>
                                _showNotAvailable(context, 'Lihat LPJ'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Status Data',
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SyncStatusBanner(
                            isOffline: state.isOffline,
                            pendingCount: state.pendingSyncCount,
                            allSynced: state.allSynced,
                            onViewData: () => _openSyncCenter(context),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTaskState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_outlined,
            color: AppColors.textSecondary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada tugas aktif hari ini.',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotAvailable(BuildContext context, String featureName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$featureName belum tersedia.')));
  }

  void _openTaskDetail(
    BuildContext context, {
    required String taskId,
    required String officerName,
    required String agencyName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskDetailController>(
          create: (_) => TaskDetailController(
            getTaskDetail: sl<GetTaskDetail>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            taskId: taskId,
          ),
          child: TaskDetailPage(
            officerName: officerName,
            agencyName: agencyName,
          ),
        ),
      ),
    );
  }

  void _openSyncCenter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<SyncCenterController>(
          create: (_) => SyncCenterController(
            repository: sl<SyncQueueRepository>(),
            backgroundSyncService: sl<BackgroundSyncService>(),
          ),
          child: const SyncCenterPage(),
        ),
      ),
    );
  }
}
