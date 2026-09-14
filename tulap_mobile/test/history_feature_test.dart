import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/session/auth_session_manager.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/history/presentation/controllers/history_controller.dart';
import 'package:tulap_mobile/features/history/presentation/pages/history_page.dart';
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
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<TaskEntity> tasks;
  _FakeTaskRepository(this.tasks);

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async {
    return Right(tasks);
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async {
    final task = tasks.firstWhere((t) => t.id == taskId);
    return Right(task);
  }

  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async {
    final task = tasks.firstWhere((t) => t.id == taskId);
    return Right(task);
  }

  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(
    String taskId,
  ) async {
    final task = tasks.firstWhere((t) => t.id == taskId);
    return Right(task);
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async {
    return Right(
      ChecklistItemEntity(
        id: itemId,
        taskId: taskId,
        label: 'Item',
        order: 1,
        isMandatory: true,
        isCompleted: isCompleted,
      ),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  final AuthUserEntity? user;
  _FakeAuthRepository(this.user);

  @override
  Future<AuthUserEntity?> getStoredUser() async => user;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();
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
  Future<Either<Failure, String>> forgotPassword(String email) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async => Right(user!);
  @override
  Future<AuthUserEntity?> refreshStoredUserFromServer() async => user;
}

class _FakeSearchArchiveRepository implements SearchArchiveRepository {
  final List<SearchResultEntity> searchResults;
  _FakeSearchArchiveRepository(this.searchResults);

  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  }) async {
    if (query.isEmpty) {
      if (filter.selectedType != null) {
        return Right(searchResults.where((r) => r.entityType == filter.selectedType).toList());
      }
      return Right(searchResults);
    }
    final q = query.toLowerCase();
    return Right(searchResults.where((r) => r.title.toLowerCase().contains(q) || (r.subtitle?.toLowerCase().contains(q) ?? false)).toList());
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10}) async {
    return Right([
      RecentSearchEntity(
        id: '1',
        query: 'monitoring kendaraan',
        searchedAt: DateTime.now(),
      ),
    ]);
  }

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
  final thisWeekDate = now.weekday > 1
      ? now.subtract(const Duration(days: 1))
      : now.add(const Duration(days: 1));

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
      destination: 'Jakarta Timur',
      startDate: now, // Today
      endDate: now,
      budgetAmount: 1500000,
      status: TaskStatusEntity.verified,
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
    TaskEntity(
      id: 'task-2',
      taskCode: 'TL-202608-0002',
      taskName: 'Pemeliharaan Jalan Sudirman',
      destination: 'Jakarta Pusat',
      startDate: thisWeekDate, // This week
      endDate: thisWeekDate,
      budgetAmount: 3000000,
      status: TaskStatusEntity.completed,
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'c2',
          taskId: 'task-2',
          label: 'Cek Aspal',
          order: 1,
          isMandatory: true,
          isCompleted: true,
        ),
      ],
      geotagPhotoCount: 5,
      expenseNoteCount: 1,
    ),
    TaskEntity(
      id: 'task-3',
      taskCode: 'TL-202608-0003',
      taskName: 'Audit Drainase Kota',
      destination: 'Jakarta Barat',
      startDate: DateTime(now.year, now.month, 1), // This month
      endDate: DateTime(now.year, now.month, 2),
      budgetAmount: 2000000,
      status: TaskStatusEntity.revisionNeeded,
      latestRevisionNote: 'Foto gorong-gorong kurang terang',
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [],
      geotagPhotoCount: 2,
      expenseNoteCount: 0,
    ),
    TaskEntity(
      id: 'task-4',
      taskCode: 'TL-202608-0004',
      taskName: 'Survei Fasilitas Umum',
      destination: 'Jakarta Selatan',
      startDate: DateTime(now.year - 1, 12, 10), // Older
      endDate: DateTime(now.year - 1, 12, 12),
      budgetAmount: 5000000,
      status: TaskStatusEntity.rejected,
      latestRevisionNote: 'Lokasi tidak sesuai GPS',
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [],
      geotagPhotoCount: 0,
      expenseNoteCount: 0,
    ),
  ];

  final sampleSearchResults = [
    SearchResultEntity(
      entityId: 'task-1',
      entityType: SearchEntityType.activity,
      title: 'Inspeksi Jembatan Ciliwung',
      subtitle: 'TL-202608-0001 • Selesai Diverifikasi',
      date: now,
      location: 'Jakarta Timur',
      relevanceScore: 90,
      syncStatus: 'SYNCED',
    ),
    SearchResultEntity(
      entityId: 'task-2',
      entityType: SearchEntityType.activity,
      title: 'Pemeliharaan Jalan Sudirman',
      subtitle: 'TL-202608-0002 • Selesai Lapangan',
      date: now.subtract(const Duration(days: 2)),
      location: 'Jakarta Pusat',
      relevanceScore: 80,
      syncStatus: 'SYNCED',
    ),
    SearchResultEntity(
      entityId: 'pd-1',
      entityType: SearchEntityType.travel,
      title: 'Perjalanan Dinas Mimika',
      subtitle: 'PD-20260828-001 • SPPD Aktif',
      date: now,
      location: 'Kabupaten Mimika',
      relevanceScore: 85,
      syncStatus: 'SYNCED',
    ),
  ];

  final sl = GetIt.instance;

  setUp(() {
    if (sl.isRegistered<AuthSessionManager>()) sl.unregister<AuthSessionManager>();
    if (sl.isRegistered<SearchArchiveController>()) sl.unregister<SearchArchiveController>();

    final authManager = AuthSessionManager(authRepository: _FakeAuthRepository(sampleUser));
    authManager.updateUser(sampleUser);
    sl.registerLazySingleton<AuthSessionManager>(() => authManager);

    final searchRepo = _FakeSearchArchiveRepository(sampleSearchResults);
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

  group('HistoryController Unit Tests', () {
    test('Initial load populates state with all tasks and computes metrics', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.status, HistoryStatus.loaded);
      expect(controller.state.allTasks.length, 4);
      expect(controller.state.filteredTasks.length, 4);
      expect(controller.state.totalVerifiedCount, 2); // 1 verified + 1 completed
      expect(controller.state.totalGeotagPhotos, 10); // 3 + 5 + 2 + 0
      expect(controller.state.totalExpenseNotes, 3); // 2 + 1 + 0 + 0
    });

    test('Filter by Date updates filteredTasks correctly', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Today
      controller.setFilter(HistoryFilter.today);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-1');

      // This Week
      controller.setFilter(HistoryFilter.thisWeek);
      expect(controller.state.filteredTasks.length, 2);

      // This Month
      controller.setFilter(HistoryFilter.thisMonth);
      expect(
        controller.state.filteredTasks.length,
        thisWeekDate.month == now.month ? 3 : 2,
      );

      // All
      controller.setFilter(HistoryFilter.all);
      expect(controller.state.filteredTasks.length, 4);
    });

    test('Search query filters tasks by title, destination, and taskCode', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Search by title
      controller.setSearchQuery('Jembatan');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-1');

      // Search by destination
      controller.setSearchQuery('Pusat');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2');

      // Clear search
      controller.clearSearch();
      expect(controller.state.filteredTasks.length, 4);
    });
  });

  group('Unified Field Archive / HistoryPage Widget Tests', () {
    testWidgets('Renders search bar, filter chips, and unified archive cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Header & Search
      expect(find.text('Arsip & Riwayat'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify Filter Chips
      expect(find.text('Semua'), findsWidgets);
      expect(find.text('Kegiatan'), findsWidgets);
      expect(find.text('Perjalanan'), findsWidgets);

      // Verify Archive Cards
      expect(find.text('Inspeksi Jembatan Ciliwung'), findsOneWidget);
      expect(find.text('Perjalanan Dinas Mimika'), findsOneWidget);
    });

    testWidgets('Tapping an entity filter chip filters visible items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 'Perjalanan' filter
      await tester.tap(find.text('Perjalanan').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Perjalanan Dinas Mimika'), findsOneWidget);
      expect(find.text('Inspeksi Jembatan Ciliwung'), findsNothing);
    });

    testWidgets('Renders empty search state when query has no matches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter query with no match
      await tester.enterText(find.byType(TextField), 'Jayapura Barat Daya');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Tidak ditemukan hasil'), findsOneWidget);
    });

    testWidgets('Renders cleanly on multiple screen sizes without overflow', (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: HistoryPage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      }
    });
  });
}
