import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../../location/presentation/pages/location_page.dart';
import '../../../lpj/presentation/pages/lpj_summary_page.dart';
import '../../../notifications/domain/services/notification_coordinator.dart';
import '../../../notifications/domain/usecases/get_unread_notification_count.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../sync_queue/presentation/controllers/sync_center_controller.dart';
import '../../../sync_queue/presentation/pages/sync_center_page.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/create_activity_page.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../task_list/presentation/controllers/task_list_controller.dart';
import '../../../task_list/presentation/pages/task_list_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/compact_sync_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/my_activities_carousel.dart';
import '../widgets/primary_task_card.dart';
import '../widgets/task_alert_bar.dart';

/// HomePage (Beranda Tulap.id)
/// ----------------------------------------------------------------------
/// Implementasi Final Beranda Tulap.id:
/// 1. HEADER (Logo Tulap.id + Sapaan dinamis waktu + Nama dinamis + Notifikasi + Avatar)
/// 2. ALERT PERHATIAN TUGAS (⚠ 2 tugas perlu perhatian hari ini →)
/// 3. TUGAS UTAMA (Cover 16:9 + Status + Info + Checklist/Dokumentasi + Lanjutkan Tugas)
/// 4. AKSI CEPAT (Foto, Nota, Lokasi, LPJ - Responsive 4-Kolom / 2x2 Grid)
/// 5. KEGIATAN SAYA (Horizontal Carousel - Maks 5 kartu - Kartu ke-2 terlihat 20-26%)
/// 6. SYNC STATUS (Compact status sinkronisasi)
/// 7. BOTTOM NAVIGATION PADDING (Aman dari FAB Kamera & Navigation bar)
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
        backgroundSyncService: sl<BackgroundSyncService>(),
        authSessionManager: sl<AuthSessionManager>(),
        getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
        getUnreadNotificationCount: sl<GetUnreadNotificationCount>(),
        notificationCoordinator: sl<NotificationCoordinator>(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Consumer<HomeController>(
          builder: (context, controller, _) {
            final state = controller.state;

            if (state.status == HomeStatus.loading) {
              return const AppLoadingView(label: 'Memuat beranda...');
            }

            final rawName = state.user?.fullName;
            final officerName =
                (rawName != null &&
                    rawName.trim().isNotEmpty &&
                    !rawName.contains('@'))
                ? rawName.trim()
                : 'Leo Tiberius';
            final agencyName =
                (state.user?.instansiName != null &&
                    state.user!.instansiName!.trim().isNotEmpty)
                ? state.user!.instansiName!.trim()
                : 'BPKAD Kabupaten Mimika';
            final activeTask = state.activeTask;
            final topActivities = state.topActivities;
            final urgentCount = state.urgentTasksCount;
            final activeCoverPhoto = activeTask != null
                ? state.taskPhotos[activeTask.id]
                : null;

            return RefreshIndicator(
              onRefresh: controller.loadHome,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  // 1. HEADER FINAL (Logo Tulap.id, Sapaan Waktu Dinamis, Nama Dinamis, Avatar)
                  HomeHeader(
                    fullName: officerName,
                    agencyName: agencyName,
                    avatarUrl: state.user?.photoUrl,
                    unreadNotificationCount: state.unreadNotificationCount,
                    onNotificationTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationsPage(
                            officerName: officerName,
                            agencyName: agencyName,
                          ),
                        ),
                      );
                      controller.refreshNotifications();
                    },
                  ),

                  // 2. ALERT PERHATIAN TUGAS
                  if (urgentCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TaskAlertBar(
                      urgentCount: urgentCount,
                      onTap: () => _openTaskList(context),
                    ),
                  ],

                  // 3. TUGAS UTAMA
                  const SizedBox(height: AppSpacing.lg),
                  if (activeTask != null)
                    PrimaryTaskCard(
                      task: activeTask,
                      coverPhotoPath: activeCoverPhoto,
                      onTap: () => _openTaskDetail(
                        context,
                        taskId: activeTask.id,
                        officerName: officerName,
                        agencyName: agencyName,
                      ),
                      onSeeAll: () => _openTaskList(context),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: _buildEmptyTaskState(context),
                    ),

                  // 4. AKSI CEPAT (Responsive 4-Kolom / 2x2 Grid)
                  const SizedBox(height: AppSpacing.xl),
                  HomeQuickActions(
                    onFoto: activeTask == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GeotagCameraEntryPage(
                                officerName: officerName,
                                agencyName: agencyName,
                                taskId: activeTask.id,
                                taskName: activeTask.taskName,
                              ),
                            ),
                          ),
                    onNota: activeTask == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReceiptScannerEntryPage(
                                taskId: activeTask.id,
                              ),
                            ),
                          ),
                    onLokasi: activeTask == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LocationPage(
                                taskDestination: activeTask.destination,
                              ),
                            ),
                          ),
                    onLpj: activeTask == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LpjSummaryPage(taskId: activeTask.id),
                            ),
                          ),
                  ),

                  // 5. KEGIATAN SAYA — HORIZONTAL CAROUSEL (Maks 5 kegiatan, kartu ke-2 terlihat 20-26%)
                  const SizedBox(height: AppSpacing.xl),
                  MyActivitiesCarousel(
                    activities: topActivities,
                    taskPhotos: state.taskPhotos,
                    onTaskTap: (task) => _openTaskDetail(
                      context,
                      taskId: task.id,
                      officerName: officerName,
                      agencyName: agencyName,
                    ),
                    onSeeAll: () => _openTaskList(context),
                  ),

                  // 6. SYNC STATUS BANNER (Compact)
                  const SizedBox(height: AppSpacing.xl),
                  CompactSyncBar(
                    isOffline: state.isOffline,
                    pendingCount: state.pendingSyncCount,
                    allSynced: state.allSynced,
                    isSyncing: state.isSyncing,
                    onViewData: () => _openSyncCenter(context),
                  ),

                  // 7. BOTTOM PADDING (Aman dari Bottom Navigation & Camera FAB)
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyTaskState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
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
          const Text(
            'Belum ada tugas aktif.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Buat Kegiatan Lapangan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () async {
              final created = await Navigator.of(context).push<TaskEntity>(
                MaterialPageRoute(builder: (_) => const CreateActivityPage()),
              );
              if (created != null && context.mounted) {
                context.read<HomeController>().load();
              }
            },
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

  void _openTaskList(BuildContext context) {
    Navigator.of(context).push(
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

  void _openTaskDetail(
    BuildContext context, {
    required String taskId,
    required String officerName,
    required String agencyName,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskDetailController>(
          create: (_) => TaskDetailController(
            getTaskDetail: sl<GetTaskDetail>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            startTask: sl<StartTask>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
            taskId: taskId,
          ),
          child: TaskDetailPage(
            officerName: officerName,
            agencyName: agencyName,
          ),
        ),
      ),
    );
    if (context.mounted) {
      context.read<HomeController>().loadHome();
    }
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
