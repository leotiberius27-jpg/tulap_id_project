import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../account/presentation/pages/display_settings_page.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../dashboard/domain/entities/action_required_entity.dart';
import '../../../dashboard/domain/usecases/get_dashboard_analytics.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../location/presentation/pages/location_page.dart';
import '../../../lpj/presentation/pages/lpj_summary_page.dart';
import '../../../notifications/domain/services/notification_coordinator.dart';
import '../../../notifications/domain/usecases/get_unread_notification_count.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../search_archive/domain/entities/search_filter_state.dart';
import '../../../search_archive/domain/entities/search_result_entity.dart';
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
import '../../../assistant/presentation/controllers/tula_visibility_controller.dart';
import '../../../task_list/presentation/controllers/task_list_controller.dart';
import '../../../task_list/presentation/pages/task_list_page.dart';
import '../../../travel_mission/presentation/pages/travel_mission_list_page.dart';
import '../../../subscription/presentation/utils/activity_quota_guard.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_required_section.dart';
import '../widgets/activity_trend_chart.dart';
import '../widgets/compact_sync_bar.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/dashboard_period_selector.dart';
import '../widgets/expense_intelligence_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/location_intelligence_card.dart';
import '../widgets/my_activities_carousel.dart';
import '../widgets/primary_task_card.dart';
import '../widgets/task_alert_bar.dart';
import '../widgets/travel_lpj_intelligence_card.dart';

/// HomePage (Beranda Tulap.id & Field Intelligence Center)
/// ----------------------------------------------------------------------
/// Implementasi Final Beranda & Field Intelligence:
/// 1. HEADER (Logo Tulap.id + Sapaan dinamis waktu + Nama dinamis + Notifikasi + Avatar)
/// 2. ALERT PERHATIAN TUGAS (⚠ X tugas perlu perhatian hari ini →)
/// 3. TUGAS UTAMA / AKTIF (Cover 16:9 + Status + Info + Checklist + Lanjutkan Tugas)
/// 4. AKSI CEPAT (Foto, Nota, Lokasi, LPJ - Responsive 4-Kolom / 2x2 Grid)
/// 5. PHASE 11: PERIOD SELECTOR (Pilihan rentang analitik: Hari Ini, 7 Hari, 30 Hari, Bulan Ini, Tahun Ini, Kustom)
/// 6. PHASE 11: 4-KPI SUMMARY GRID (Kegiatan, Perjalanan, Dokumentasi, Pengeluaran dengan Rupiah)
/// 7. PHASE 11: ACTION REQUIRED (⚠ LPJ Belum Lengkap, ⚠ Bukti Belum Tersinkronisasi, ⚠ Nota Perlu Ditinjau)
/// 8. PHASE 11: ACTIVITY TREND CHART (Grafik interaktif dengan tooltip dan drilldown tanggal)
/// 9. PHASE 11: LOCATION INTELLIGENCE (Peta sebaran & top lokasi dengan drilldown)
/// 10. PHASE 11: EXPENSE INTELLIGENCE (Breakdown kategori & progress bar terkonfirmasi)
/// 11. PHASE 11: TRAVEL & LPJ INTELLIGENCE (Hari dinas & kelengkapan LPJ)
/// 12. KEGIATAN SAYA (Horizontal Carousel - Maks 5 kartu)
/// 13. SYNC STATUS (Compact status sinkronisasi)
/// 14. BOTTOM NAVIGATION PADDING (Aman dari FAB Kamera & Navigation bar)
/// ----------------------------------------------------------------------
class HomePage extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomePage({super.key, this.onNavigateToTab});

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
        getDashboardAnalytics: sl.isRegistered<GetDashboardAnalytics>()
            ? sl<GetDashboardAnalytics>()
            : null,
      ),
      child: _HomeView(onNavigateToTab: onNavigateToTab),
    );
  }
}

class _HomeView extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const _HomeView({this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Consumer<HomeController>(
          builder: (context, controller, _) {
            final state = controller.state;

            if (state.status == HomeStatus.loading &&
                state.allActiveTasks.isEmpty) {
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
            final summary = state.dashboardSummary;

            // Tula: tandai ada insight yang perlu perhatian user (tugas
            // mendesak, item aksi tertunda, atau bukti belum tersinkron)
            // tanpa membangun ulang pipeline data - cukup baca state yang
            // sudah dimuat HomeController.
            final String? tulaInsightMessage = urgentCount > 0
                ? (activeTask != null
                      ? '$urgentCount checklist belum selesai'
                      : '$urgentCount tugas perlu perhatian')
                : state.pendingSyncCount > 0
                ? '${state.pendingSyncCount} data menunggu internet'
                : (summary?.actionRequired.isNotEmpty ?? false)
                ? '${summary!.actionRequired.length} hal perlu ditinjau'
                : null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final tula = sl<TulaVisibilityController>();
              // Beranda tetap "mounted" selamanya di dalam IndexedStack
              // MainShell - jangan timpa insight/badge milik layar lain
              // yang sedang benar-benar di atas (mis. Detail Tugas, LPJ).
              if (tula.current.screen != TulaScreenContext.home) return;
              tula.setInsight(
                has: tulaInsightMessage != null,
                severity: tulaInsightMessage != null
                    ? TulaInsightSeverity.warning
                    : null,
                message: tulaInsightMessage,
              );
            });

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
                    onLogoTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DisplaySettingsPage(),
                        ),
                      );
                    },
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
                    onProfileTap: () {
                      if (onNavigateToTab != null) {
                        onNavigateToTab!(3);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountPage(),
                          ),
                        );
                      }
                    },
                  ),

                  // 2. ALERT PERHATIAN TUGAS
                  if (urgentCount > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TaskAlertBar(
                      urgentCount: urgentCount,
                      onTap: () => _openTaskList(context),
                    ),
                  ],

                  // 3. TUGAS UTAMA / AKTIF
                  const SizedBox(height: AppSpacing.md),
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

                  // 5. PHASE 11: PERIOD SELECTOR
                  const SizedBox(height: AppSpacing.xl),
                  DashboardPeriodSelector(
                    selectedPeriod: state.safePeriod,
                    onPeriodChanged: (p) => controller.onPeriodChanged(p),
                  ),

                  // 6. PHASE 11: 4-KPI SUMMARY GRID
                  if (summary != null) ...[
                    const SizedBox(height: 8),
                    DashboardKpiGrid(
                      summary: summary,
                      onActivityTap: () => _drilldownToSearch(
                        context,
                        entityType: SearchEntityType.activity,
                        periodState: state,
                      ),
                      onTravelTap: () => _drilldownToSearch(
                        context,
                        entityType: SearchEntityType.travel,
                        periodState: state,
                      ),
                      onEvidenceTap: () => _drilldownToSearch(
                        context,
                        entityType: SearchEntityType.evidence,
                        periodState: state,
                      ),
                      onExpenseTap: () => _drilldownToSearch(
                        context,
                        entityType: SearchEntityType.expense,
                        periodState: state,
                      ),
                    ),

                    // 7. PHASE 11: ACTION REQUIRED SECTION
                    if (summary.actionRequired.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ActionRequiredSection(
                        actionItems: summary.actionRequired,
                        onItemTap: (item) =>
                            _handleActionRequiredTap(context, item, state),
                      ),
                    ],

                    // 8. PHASE 11: ACTIVITY TREND CHART
                    if (summary.activityTrend.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ActivityTrendChart(
                        trendPoints: summary.activityTrend,
                        onPointTap: (point) {
                          _drilldownToSearch(
                            context,
                            query: point.label,
                            periodState: state,
                          );
                        },
                      ),
                    ],

                    // 9. PHASE 11: LOCATION INTELLIGENCE
                    if (summary.topLocations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      LocationIntelligenceCard(
                        topLocations: summary.topLocations,
                        onLocationTap: (loc) => _drilldownToSearch(
                          context,
                          location: loc,
                          periodState: state,
                        ),
                      ),
                    ],

                    // 10. PHASE 11: EXPENSE INTELLIGENCE
                    if (summary.expenseTotal > 0 ||
                        summary.expenseByCategory.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ExpenseIntelligenceCard(
                        totalExpense: summary.expenseTotal,
                        categories: summary.expenseByCategory,
                        onCategoryTap: (cat) => _drilldownToSearch(
                          context,
                          entityType: SearchEntityType.expense,
                          category: cat,
                          periodState: state,
                        ),
                      ),
                    ],

                    // 11. PHASE 11: TRAVEL & LPJ INTELLIGENCE
                    if (summary.travelTotal > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      TravelLpjIntelligenceCard(
                        travelTotal: summary.travelTotal,
                        travelDays: summary.travelDays,
                        lpjComplete: summary.lpjComplete,
                        lpjIncomplete: summary.lpjIncomplete,
                        destinations: summary.travelDestinations,
                        onTravelTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TravelMissionListPage(),
                          ),
                        ),
                        onIncompleteLpjTap: () => _drilldownToSearch(
                          context,
                          entityType: SearchEntityType.lpj,
                          periodState: state,
                        ),
                      ),
                    ],
                  ],

                  // 12. KEGIATAN SAYA — HORIZONTAL CAROUSEL
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

                  // 13. SYNC STATUS BANNER (Compact)
                  const SizedBox(height: AppSpacing.xl),
                  CompactSyncBar(
                    isOffline: state.isOffline,
                    pendingCount: state.pendingSyncCount,
                    allSynced: state.allSynced,
                    isSyncing: state.isSyncing,
                    onViewData: () => _openSyncCenter(context),
                  ),

                  // 14. BOTTOM PADDING (Aman dari Bottom Navigation & Camera FAB)
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _drilldownToSearch(
    BuildContext context, {
    SearchEntityType? entityType,
    String? location,
    String? category,
    String? query,
    required HomeState periodState,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          initialQuery: query,
          initialFilter: SearchFilterState(
            selectedType: entityType,
            location: location,
            expenseCategory: category,
            startDate: periodState.safePeriod.startDate,
            endDate: periodState.safePeriod.endDate,
          ),
        ),
      ),
    );
  }

  void _handleActionRequiredTap(
    BuildContext context,
    ActionRequiredEntity item,
    HomeState state,
  ) {
    switch (item.type) {
      case ActionRequiredType.pendingSync:
        _openSyncCenter(context);
        break;
      case ActionRequiredType.lpjIncomplete:
        _drilldownToSearch(
          context,
          entityType: SearchEntityType.lpj,
          periodState: state,
        );
        break;
      case ActionRequiredType.receiptNeedsReview:
        _drilldownToSearch(
          context,
          entityType: SearchEntityType.receipt,
          periodState: state,
        );
        break;
      case ActionRequiredType.activityIncomplete:
        _drilldownToSearch(
          context,
          entityType: SearchEntityType.activity,
          periodState: state,
        );
        break;
      case ActionRequiredType.integrityIssue:
        _drilldownToSearch(
          context,
          entityType: SearchEntityType.evidence,
          periodState: state,
        );
        break;
    }
  }

  Widget _buildEmptyTaskState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Belum ada kegiatan aktif',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Buat tugas dinas baru atau tunggu penugasan dari atasan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () async {
              final canCreate = await ensureActivityQuotaAvailable(context);
              if (!canCreate || !context.mounted) return;
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const CreateActivityPage()),
              );
              if (result == true) {
                if (context.mounted) {
                  context.read<HomeController>().loadHome();
                }
              }
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Buat Kegiatan Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
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
            taskId: taskId,
            getTaskDetail: sl<GetTaskDetail>(),
            startTask: sl<StartTask>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
          ),
          child: TaskDetailPage(
            officerName: officerName,
            agencyName: agencyName,
          ),
        ),
      ),
    );
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
