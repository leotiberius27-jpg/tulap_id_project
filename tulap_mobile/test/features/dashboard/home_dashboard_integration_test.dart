import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/core/session/auth_session_manager.dart';
import 'package:tulap_mobile/core/sync/background_sync_service.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/action_required_entity.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/activity_trend_point.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/dashboard_period.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/expense_category_stat.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/top_location_stat.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/travel_destination_stat.dart';
import 'package:tulap_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tulap_mobile/features/dashboard/domain/usecases/get_dashboard_analytics.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/home/presentation/pages/home_page.dart';
import 'package:tulap_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:tulap_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:tulap_mobile/features/notifications/domain/services/notification_coordinator.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/create_or_update_notification.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/get_unread_notification_count.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/recent_search_entity.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_filter_state.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_result_entity.dart';
import 'package:tulap_mobile/features/search_archive/domain/repositories/search_archive_repository.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/clear_recent_searches.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/get_available_years.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/get_recent_searches.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/rebuild_search_index.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/save_recent_search.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/unified_search.dart';
import 'package:tulap_mobile/features/search_archive/presentation/controllers/search_archive_controller.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/repositories/sync_queue_repository.dart';
import 'package:tulap_mobile/features/sync_queue/domain/usecases/process_sync_queue.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/start_task.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/submit_task_for_verification.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/toggle_checklist_item.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<TaskEntity> tasks;
  _FakeTaskRepository(this.tasks);

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async => Right(tasks);
  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async =>
      Right(tasks.firstWhere((t) => t.id == taskId));
  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async =>
      Right(tasks.firstWhere((t) => t.id == taskId));
  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(String taskId) async =>
      Right(tasks.firstWhere((t) => t.id == taskId));
  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async => Right(
        ChecklistItemEntity(
          id: itemId,
          taskId: taskId,
          label: 'Checklist',
          order: 1,
          isMandatory: true,
          isCompleted: isCompleted,
        ),
      );
}

class _FakeAuthRepository implements AuthRepository {
  final AuthUserEntity? user;
  _FakeAuthRepository(this.user);

  @override
  Future<AuthUserEntity?> getStoredUser() async => user;
  @override
  Future<Either<Failure, AuthUserEntity>> login({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<Either<Failure, AuthUserEntity>> selfRegister({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, String>> forgotPassword(String email) => throw UnimplementedError();
  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({required String idToken, String? email, String? displayName}) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({required String identityToken, String? fullName}) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({required String accessToken, String? email, String? fullName}) =>
      throw UnimplementedError();
  @override
  Future<bool> isBiometricLoginEnabled() async => false;
  @override
  Future<void> enableBiometricLogin() async {}
  @override
  Future<void> disableBiometricLogin() async {}
  @override
  Future<AuthUserEntity?> getBiometricGreetingUser() async => user;
  @override
  Future<AuthUserEntity?> restoreBiometricSession() async => user;
  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async => Right(user!);
}

class _FakeSyncQueueRepository implements SyncQueueRepository {
  @override
  Future<Either<Failure, List<SyncRecordEntity>>> getAllRecords() async => const Right([]);
  @override
  Future<Either<Failure, void>> enqueueRecord(SyncRecordEntity record) async => const Right(null);
  @override
  Future<Either<Failure, SyncRecordEntity>> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required String entityLocalId,
    String? taskId,
    required Map<String, dynamic> payload,
    String? filePath,
  }) async => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> updateRecordStatus(String id, SyncStatus status, {String? errorMessage}) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteRecord(String id) async => const Right(null);
  @override
  Future<Either<Failure, void>> clearCompletedRecords() async => const Right(null);
  @override
  Future<Either<Failure, SyncRecordEntity>> processRecord(String recordId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> retryRecord(String recordId) async => const Right(null);
}

class _FakeNetworkInfo implements NetworkInfo {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;
  @override
  Connectivity get connectivity => Connectivity();
  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
}

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardSummaryEntity summary;
  _FakeDashboardRepository(this.summary);

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardAnalytics({
    required DashboardPeriod period,
    bool forceOffline = false,
  }) async {
    return Right(summary);
  }
}

class _FakeGeotagCameraLocalDataSource implements GeotagCameraLocalDataSource {
  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationsRepository implements NotificationsRepository {
  final _controller = StreamController<int>.broadcast();
  @override
  Future<Either<Failure, int>> getUnreadCount() async => const Right(0);
  @override
  Stream<int> get unreadCountStream => _controller.stream;
  @override
  Future<Either<Failure, NotificationListResult>> getNotifications({
    NotificationCategory? category,
  }) async =>
      const Right(NotificationListResult(items: [], unreadCount: 0));
  @override
  Future<Either<Failure, void>> markRead(String id) async => const Right(null);
  @override
  Future<Either<Failure, void>> markAllRead() async => const Right(null);
  @override
  Future<Either<Failure, int>> deleteReadNotifications() async => const Right(0);
  @override
  Future<Either<Failure, void>> createOrUpdateNotification(
    NotificationEntity notification,
  ) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteNotification(String id) async => const Right(null);
}

class _FakeSearchArchiveRepository implements SearchArchiveRepository {
  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  }) async => const Right([]);
  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10}) async => const Right([]);
  @override
  Future<Either<Failure, void>> saveRecentSearch(String query) async => const Right(null);
  @override
  Future<Either<Failure, void>> removeRecentSearch(String id) async => const Right(null);
  @override
  Future<Either<Failure, void>> clearRecentSearches() async => const Right(null);
  @override
  Future<Either<Failure, int>> backfillSearchIndex() async => const Right(10);
  @override
  Future<Either<Failure, void>> rebuildSearchIndex() async => const Right(null);
  @override
  Future<Either<Failure, List<int>>> getAvailableYears() async => const Right([2026, 2025]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final now = DateTime.now();

  final sampleUser = AuthUserEntity(
    id: 'user-001',
    email: 'petugas@tulap.id',
    fullName: 'Leonardo Petugas',
    role: 'PEGAWAI',
    instansiName: 'Dinas Pekerjaan Umum',
  );

  final sampleTasks = [
    TaskEntity(
      id: 'task-1',
      taskCode: 'TL-202608-0001',
      taskName: 'Inspeksi Jembatan Ciliwung',
      destination: 'Kabupaten Mimika, Papua',
      startDate: now,
      endDate: now,
      budgetAmount: 1500000,
      status: TaskStatusEntity.ongoing,
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'c1',
          taskId: 'task-1',
          label: 'Cek Pondasi',
          order: 1,
          isMandatory: true,
          isCompleted: true,
        ),
      ],
      geotagPhotoCount: 3,
      expenseNoteCount: 2,
    ),
  ];

  final period = DashboardPeriod.thisMonth(now: now);

  final sampleSummary = DashboardSummaryEntity(
    period: period,
    activityTotal: 24,
    activityCompleted: 18,
    activityOngoing: 6,
    activityCompletionRate: 75.0,
    photoCount: 104,
    videoCount: 22,
    evidenceTotal: 126,
    travelTotal: 8,
    travelCompleted: 6,
    travelDays: 14,
    expenseTotal: 8750000,
    lpjComplete: 6,
    lpjIncomplete: 2,
    actionRequired: const [
      ActionRequiredEntity(
        type: ActionRequiredType.lpjIncomplete,
        title: '2 LPJ belum lengkap',
        subtitle: 'Lengkapi dokumen perjalanan dinas',
        count: 2,
        severity: ActionRequiredSeverity.warning,
      ),
      ActionRequiredEntity(
        type: ActionRequiredType.pendingSync,
        title: '5 bukti belum tersinkronisasi',
        subtitle: 'Periksa koneksi internet & sinkronkan data',
        count: 5,
        severity: ActionRequiredSeverity.warning,
      ),
      ActionRequiredEntity(
        type: ActionRequiredType.receiptNeedsReview,
        title: '2 nota perlu ditinjau',
        subtitle: 'Periksa hasil pindaian OCR & konfirmasi nominal',
        count: 2,
        severity: ActionRequiredSeverity.info,
      ),
    ],
    activityTrend: [
      const ActivityTrendPoint(date: '2026-08-10', label: '10 Agu', count: 4),
      const ActivityTrendPoint(date: '2026-08-15', label: '15 Agu', count: 8),
      const ActivityTrendPoint(date: '2026-08-20', label: '20 Agu', count: 6),
      const ActivityTrendPoint(date: '2026-08-25', label: '25 Agu', count: 6),
    ],
    expenseByCategory: const [
      ExpenseCategoryStat(category: 'Transportasi', amount: 3200000, percentage: 36.6, count: 4),
      ExpenseCategoryStat(category: 'Penginapan', amount: 2400000, percentage: 27.4, count: 2),
      ExpenseCategoryStat(category: 'BBM', amount: 1850000, percentage: 21.1, count: 8),
      ExpenseCategoryStat(category: 'Konsumsi', amount: 1300000, percentage: 14.9, count: 6),
    ],
    topLocations: const [
      TopLocationStat(location: 'Mimika', count: 18, latitude: -4.54, longitude: 136.88),
      TopLocationStat(location: 'Jayapura', count: 4, latitude: -2.53, longitude: 140.71),
      TopLocationStat(location: 'Nabire', count: 2, latitude: -3.36, longitude: 135.49),
    ],
    travelDestinations: const [
      TravelDestinationStat(destination: 'Jayapura', count: 3),
      TravelDestinationStat(destination: 'Nabire', count: 2),
      TravelDestinationStat(destination: 'Timika', count: 2),
    ],
    insights: const [
      '18 dari 24 kegiatan lapangan telah selesai.',
      'Pusat kegiatan utama pada periode ini berada di Mimika.',
      'Alokasi pengeluaran terbesar dicatat pada kategori Transportasi.',
    ],
    isOfflineDerived: false,
  );

  final sl = GetIt.instance;

  setUp(() {
    sl.reset();

    final authManager = AuthSessionManager(authRepository: _FakeAuthRepository(sampleUser));
    authManager.updateUser(sampleUser);
    sl.registerLazySingleton<AuthSessionManager>(() => authManager);

    final taskRepo = _FakeTaskRepository(sampleTasks);
    sl.registerLazySingleton<GetActiveTasks>(() => GetActiveTasks(taskRepo));
    sl.registerLazySingleton<GetTaskDetail>(() => GetTaskDetail(taskRepo));
    sl.registerLazySingleton<StartTask>(() => StartTask(taskRepo));
    sl.registerLazySingleton<SubmitTaskForVerification>(() => SubmitTaskForVerification(taskRepo));
    sl.registerLazySingleton<ToggleChecklistItem>(() => ToggleChecklistItem(taskRepo));

    sl.registerLazySingleton<GetCurrentSession>(() => GetCurrentSession(_FakeAuthRepository(sampleUser)));
    final syncRepo = _FakeSyncQueueRepository();
    sl.registerLazySingleton<SyncQueueRepository>(() => syncRepo);
    final netInfo = _FakeNetworkInfo();
    sl.registerLazySingleton<NetworkInfo>(() => netInfo);
    sl.registerLazySingleton<BackgroundSyncService>(
      () => BackgroundSyncService(
        processSyncQueue: ProcessSyncQueue(
          repository: syncRepo,
          networkInfo: netInfo,
        ),
        networkInfo: netInfo,
      ),
    );

    final notifRepo = _FakeNotificationsRepository();
    sl.registerLazySingleton<GetUnreadNotificationCount>(() => GetUnreadNotificationCount(notifRepo));
    sl.registerLazySingleton<NotificationCoordinator>(
      () => NotificationCoordinator(
        createOrUpdateNotification: CreateOrUpdateNotification(notifRepo),
        notificationsRepository: notifRepo,
        authSessionManager: authManager,
      ),
    );

    final photoDataSource = _FakeGeotagCameraLocalDataSource();
    sl.registerLazySingleton<GetTaskPhotoPreviews>(() => GetTaskPhotoPreviews(photoDataSource));

    final dashRepo = _FakeDashboardRepository(sampleSummary);
    sl.registerLazySingleton<GetDashboardAnalytics>(() => GetDashboardAnalytics(dashRepo));

    final searchRepo = _FakeSearchArchiveRepository();
    sl.registerFactory<SearchArchiveController>(
      () => SearchArchiveController(
        unifiedSearch: UnifiedSearch(searchRepo),
        getRecentSearches: GetRecentSearches(searchRepo),
        saveRecentSearch: SaveRecentSearch(searchRepo),
        clearRecentSearches: ClearRecentSearches(searchRepo),
        rebuildSearchIndex: RebuildSearchIndex(searchRepo),
        getAvailableYears: GetAvailableYears(searchRepo),
      ),
    );
  });

  group('Phase 11: Home Dashboard & Field Intelligence Tests', () {
    testWidgets('Renders complete Executive Dashboard with all Phase 11 widgets', (tester) async {
      tester.view.physicalSize = const Size(500, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header & Greeting
      expect(find.text('Leonardo Petugas'), findsOneWidget);

      // 2. Period Selector
      expect(find.text('Ringkasan & Analisis'), findsOneWidget);

      // 3. 4-KPI Grid
      expect(find.text('Kegiatan'), findsWidgets);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Perjalanan'), findsWidgets);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Dokumentasi'), findsWidgets);
      expect(find.text('126'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsWidgets);
      expect(find.text('Rp8,75 jt'), findsOneWidget);

      // 4. Action Required Section
      expect(find.text('Perlu Perhatian'), findsOneWidget);
      expect(find.text('2 LPJ belum lengkap'), findsOneWidget);
      expect(find.text('5 bukti belum tersinkronisasi'), findsOneWidget);
      expect(find.text('2 nota perlu ditinjau'), findsOneWidget);

      // 5. Activity Trend Chart
      expect(find.text('Aktivitas Periode Ini'), findsOneWidget);
      expect(find.text('24 kegiatan'), findsOneWidget);

      // 6. Location Intelligence
      expect(find.text('Peta & Sebaran Lokasi'), findsOneWidget);
      expect(find.text('Mimika'), findsWidgets);

      // 7. Expense Intelligence
      expect(find.text('Pengeluaran Periode Ini'), findsOneWidget);
      expect(find.text('Transportasi'), findsWidgets);
      expect(find.text('Penginapan'), findsWidgets);
      expect(find.text('BBM'), findsWidgets);

      // 8. Travel & LPJ Intelligence
      expect(find.text('Perjalanan Dinas & SPPD'), findsOneWidget);
      expect(find.text('14 Hari'), findsOneWidget);
    });

    testWidgets('Renders cleanly on various screen resolutions without overflow', (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(375, 812),
        const Size(390, 844),
        const Size(412, 915),
        const Size(430, 932),
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });
  });
}
