import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../dashboard/domain/entities/dashboard_period.dart';
import '../../../dashboard/domain/entities/dashboard_summary_entity.dart';
import '../../../dashboard/domain/usecases/get_dashboard_analytics.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../notifications/domain/services/notification_coordinator.dart';
import '../../../notifications/domain/usecases/get_unread_notification_count.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../domain/home_category.dart';

enum HomeStatus { loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final AuthUserEntity? user;
  final TaskEntity? activeTask;
  final List<TaskEntity> allActiveTasks;
  final Map<String, String?> taskPhotos;
  final HomeCategory selectedCategory;
  final bool isOffline;
  final int pendingSyncCount;
  final int unreadNotificationCount;
  final bool allSynced;
  final bool isSyncing;
  final String? errorMessage;

  // Phase 11: Dashboard & Field Intelligence
  final DashboardPeriod? selectedPeriod;
  final DashboardSummaryEntity? dashboardSummary;
  final bool isLoadingDashboard;

  const HomeState({
    this.status = HomeStatus.loading,
    this.user,
    this.activeTask,
    this.allActiveTasks = const [],
    this.taskPhotos = const {},
    this.selectedCategory = HomeCategory.semua,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.unreadNotificationCount = 0,
    this.allSynced = false,
    this.isSyncing = false,
    this.errorMessage,
    this.selectedPeriod,
    this.dashboardSummary,
    this.isLoadingDashboard = false,
  });

  /// Helper getter for safe selected period
  DashboardPeriod get safePeriod => selectedPeriod ?? DashboardPeriod.thisMonth();

  /// Daftar kegiatan prioritas di carousel horizontal (maksimal 5 kegiatan)
  List<TaskEntity> get topActivities {
    final tasks = List<TaskEntity>.from(allActiveTasks);
    tasks.sort((a, b) {
      int score(TaskEntity t) {
        switch (t.status) {
          case TaskStatusEntity.ongoing:
            return 1;
          case TaskStatusEntity.revisionNeeded:
            return 2;
          case TaskStatusEntity.pendingVerification:
            return 3;
          case TaskStatusEntity.verified:
          case TaskStatusEntity.completed:
            return 4;
          case TaskStatusEntity.draft:
          case TaskStatusEntity.rejected:
            return 5;
        }
      }

      final sA = score(a);
      final sB = score(b);
      if (sA != sB) return sA.compareTo(sB);
      return b.startDate.compareTo(a.startDate);
    });
    return tasks.take(5).toList();
  }

  /// Jumlah tugas yang butuh perhatian hari ini
  int get urgentTasksCount => allActiveTasks
      .where(
        (t) =>
            t.status == TaskStatusEntity.ongoing ||
            t.status == TaskStatusEntity.revisionNeeded,
      )
      .length;

  List<TaskEntity> get urgentTasks =>
      allActiveTasks
          .where(
            (t) =>
                (t.status == TaskStatusEntity.ongoing ||
                    t.status == TaskStatusEntity.revisionNeeded) &&
                _matchesCategory(t),
          )
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<TaskEntity> get filteredTasks =>
      allActiveTasks.where(_matchesCategory).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  bool _matchesCategory(TaskEntity task) {
    if (selectedCategory == HomeCategory.semua) return true;
    return categorizeTask(task) == selectedCategory;
  }

  HomeState copyWith({
    HomeStatus? status,
    AuthUserEntity? user,
    TaskEntity? activeTask,
    List<TaskEntity>? allActiveTasks,
    Map<String, String?>? taskPhotos,
    HomeCategory? selectedCategory,
    bool? isOffline,
    int? pendingSyncCount,
    int? unreadNotificationCount,
    bool? allSynced,
    bool? isSyncing,
    String? errorMessage,
    DashboardPeriod? selectedPeriod,
    DashboardSummaryEntity? dashboardSummary,
    bool? isLoadingDashboard,
  }) {
    return HomeState(
      status: status ?? this.status,
      user: user ?? this.user,
      activeTask: activeTask ?? this.activeTask,
      allActiveTasks: allActiveTasks ?? this.allActiveTasks,
      taskPhotos: taskPhotos ?? this.taskPhotos,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isOffline: isOffline ?? this.isOffline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
      allSynced: allSynced ?? this.allSynced,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedPeriod: selectedPeriod ?? safePeriod,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      isLoadingDashboard: isLoadingDashboard ?? this.isLoadingDashboard,
    );
  }
}

/// HomeController
/// ----------------------------------------------------------------------
class HomeController extends ChangeNotifier {
  final GetCurrentSession _getCurrentSession;
  final GetActiveTasks _getActiveTasks;
  final GetTaskDetail _getTaskDetail;
  final SyncQueueRepository _syncQueueRepository;
  final NetworkInfo _networkInfo;
  final BackgroundSyncService _backgroundSyncService;
  final AuthSessionManager? _authSessionManager;
  final GetTaskPhotoPreviews? _getTaskPhotoPreviews;
  final GetUnreadNotificationCount? _getUnreadNotificationCount;
  final NotificationCoordinator? _notificationCoordinator;
  final GetDashboardAnalytics? _getDashboardAnalytics;

  StreamSubscription<int>? _unreadSubscription;

  HomeState _state = HomeState(selectedPeriod: DashboardPeriod.thisMonth());
  HomeState get state => _state;

  HomeController({
    required GetCurrentSession getCurrentSession,
    required GetActiveTasks getActiveTasks,
    required GetTaskDetail getTaskDetail,
    required SyncQueueRepository syncQueueRepository,
    required NetworkInfo networkInfo,
    required BackgroundSyncService backgroundSyncService,
    AuthSessionManager? authSessionManager,
    GetTaskPhotoPreviews? getTaskPhotoPreviews,
    GetUnreadNotificationCount? getUnreadNotificationCount,
    NotificationCoordinator? notificationCoordinator,
    GetDashboardAnalytics? getDashboardAnalytics,
  })  : _getCurrentSession = getCurrentSession,
        _getActiveTasks = getActiveTasks,
        _getTaskDetail = getTaskDetail,
        _syncQueueRepository = syncQueueRepository,
        _networkInfo = networkInfo,
        _backgroundSyncService = backgroundSyncService,
        _authSessionManager = authSessionManager,
        _getTaskPhotoPreviews = getTaskPhotoPreviews,
        _getUnreadNotificationCount = getUnreadNotificationCount,
        _notificationCoordinator = notificationCoordinator,
        _getDashboardAnalytics = getDashboardAnalytics {
    loadHome();
    _backgroundSyncService.addListener(_onBackgroundSyncChanged);
    _authSessionManager?.addListener(_onUserSessionChanged);

    _unreadSubscription = _getUnreadNotificationCount?.stream.listen((count) {
      if (_state.unreadNotificationCount != count) {
        _update(_state.copyWith(unreadNotificationCount: count));
      }
    });
  }

  void _onUserSessionChanged() {
    final updatedUser = _authSessionManager?.currentUser;
    if (_state.user != updatedUser) {
      _update(_state.copyWith(user: updatedUser));
      refreshNotifications();
    }
  }

  void _onBackgroundSyncChanged() {
    _update(_state.copyWith(isSyncing: _backgroundSyncService.isSyncing));
    if (!_backgroundSyncService.isSyncing) {
      _refreshSyncStatus();
    }
  }

  Future<void> refreshNotifications() async {
    final unreadResult = await _getUnreadNotificationCount?.call();
    final count = unreadResult?.fold((_) => 0, (c) => c) ?? _state.unreadNotificationCount;
    _update(_state.copyWith(unreadNotificationCount: count));
  }

  Future<void> _refreshSyncStatus() async {
    final isOnline = await _networkInfo.isConnected;
    final syncResult = await _syncQueueRepository.getAllRecords();
    final records = syncResult.fold(
      (_) => const <SyncRecordEntity>[],
      (records) => records,
    );
    final pendingCount = records
        .where((r) => r.status != SyncStatus.synced)
        .length;
    final failedCount = records
        .where((r) => r.status == SyncStatus.failed)
        .length;
    final syncedCount = records
        .where((r) => r.status == SyncStatus.synced)
        .length;

    await _notificationCoordinator?.evaluateSyncQueue(
      pendingCount: pendingCount,
      failedCount: failedCount,
      syncedCount: syncedCount,
    );

    final unreadResult = await _getUnreadNotificationCount?.call();
    final unreadCount = unreadResult?.fold((_) => 0, (c) => c) ?? _state.unreadNotificationCount;

    _update(
      _state.copyWith(
        isOffline: !isOnline,
        pendingSyncCount: pendingCount,
        unreadNotificationCount: unreadCount,
        allSynced: records.isNotEmpty && pendingCount == 0,
      ),
    );
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _unreadSubscription?.cancel();
    _authSessionManager?.removeListener(_onUserSessionChanged);
    _backgroundSyncService.removeListener(_onBackgroundSyncChanged);
    super.dispose();
  }

  void _update(HomeState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> load() => loadHome();

  Future<void> loadHome() async {
    FastLocationService.instance.startWarmUp();
    _update(_state.copyWith(status: HomeStatus.loading));

    final user = _authSessionManager?.currentUser ?? await _getCurrentSession();
    if (_authSessionManager != null && _authSessionManager.currentUser == null && user != null) {
      _authSessionManager.updateUser(user);
    }
    final isOnline = await _networkInfo.isConnected;

    TaskEntity? activeTask;
    List<TaskEntity> allActiveTasks = const [];
    final tasksResult = await _getActiveTasks();
    await tasksResult.fold(
      (_) async {
        activeTask = null;
      },
      (tasks) async {
        allActiveTasks = tasks;
        final candidate = _pickActiveTask(tasks);
        if (candidate != null) {
          final detailResult = await _getTaskDetail(candidate.id);
          activeTask = detailResult.fold((_) => candidate, (detail) => detail);
        }
      },
    );

    // Muat cover photo untuk tugas-tugas aktif
    final Map<String, String?> photoMap = {};
    if (_getTaskPhotoPreviews != null) {
      for (final task in allActiveTasks) {
        final photosResult = await _getTaskPhotoPreviews(task.id);
        photosResult.fold((_) => null, (photos) {
          if (photos.isNotEmpty) {
            photoMap[task.id] = photos.first.localFilePath;
          }
        });
      }
    }

    final syncResult = await _syncQueueRepository.getAllRecords();
    final records = syncResult.fold(
      (_) => const <SyncRecordEntity>[],
      (records) => records,
    );
    final pendingCount = records
        .where((r) => r.status != SyncStatus.synced)
        .length;
    final failedCount = records
        .where((r) => r.status == SyncStatus.failed)
        .length;
    final syncedCount = records
        .where((r) => r.status == SyncStatus.synced)
        .length;

    // Evaluasi notifikasi antrean sinkronisasi
    await _notificationCoordinator?.evaluateSyncQueue(
      pendingCount: pendingCount,
      failedCount: failedCount,
      syncedCount: syncedCount,
    );

    // Evaluasi notifikasi kegiatan aktif
    if (activeTask != null && activeTask!.status == TaskStatusEntity.ongoing) {
      final completed = activeTask!.checklistItems.where((c) => c.isCompleted).length;
      final total = activeTask!.checklistItems.length;
      await _notificationCoordinator?.notifyActiveTask(
        taskId: activeTask!.id,
        taskName: activeTask!.taskName,
        completedChecklists: completed,
        totalChecklists: total,
      );
    }

    // Ambil hitungan real notifikasi yang belum dibaca
    final unreadResult = await _getUnreadNotificationCount?.call();
    final unreadCount = unreadResult?.fold((_) => 0, (c) => c) ?? 0;

    // Phase 11: Muat analitik dashboard
    DashboardSummaryEntity? dashboardSummary;
    final activePeriod = _state.safePeriod;
    if (_getDashboardAnalytics != null) {
      final summaryResult = await _getDashboardAnalytics(period: activePeriod);
      dashboardSummary = summaryResult.fold((_) => null, (s) => s);
    }

    _update(
      HomeState(
        status: HomeStatus.loaded,
        user: user,
        activeTask: activeTask,
        allActiveTasks: allActiveTasks,
        taskPhotos: photoMap,
        selectedCategory: _state.selectedCategory,
        isOffline: !isOnline,
        pendingSyncCount: pendingCount,
        unreadNotificationCount: unreadCount,
        allSynced: records.isNotEmpty && pendingCount == 0,
        selectedPeriod: activePeriod,
        dashboardSummary: dashboardSummary,
        isLoadingDashboard: false,
      ),
    );
  }

  /// Change dashboard analytics period
  Future<void> onPeriodChanged(DashboardPeriod newPeriod) async {
    _update(_state.copyWith(
      selectedPeriod: newPeriod,
      isLoadingDashboard: true,
    ));

    if (_getDashboardAnalytics != null) {
      final result = await _getDashboardAnalytics(period: newPeriod);
      result.fold(
        (_) => _update(_state.copyWith(isLoadingDashboard: false)),
        (summary) => _update(_state.copyWith(
          dashboardSummary: summary,
          isLoadingDashboard: false,
        )),
      );
    } else {
      _update(_state.copyWith(isLoadingDashboard: false));
    }
  }

  void setCategory(HomeCategory category) {
    _update(_state.copyWith(selectedCategory: category));
  }

  TaskEntity? _pickActiveTask(List<TaskEntity> tasks) {
    const priorityOrder = [
      TaskStatusEntity.ongoing,
      TaskStatusEntity.revisionNeeded,
      TaskStatusEntity.draft,
      TaskStatusEntity.pendingVerification,
    ];

    for (final status in priorityOrder) {
      final matches = tasks.where((t) => t.status == status).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (matches.isNotEmpty) return matches.first;
    }

    return null;
  }
}
