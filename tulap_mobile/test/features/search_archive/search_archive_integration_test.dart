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
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/history/presentation/pages/history_page.dart';
import 'package:tulap_mobile/features/search_archive/presentation/widgets/search_filter_chips.dart';
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
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/start_task.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/submit_task_for_verification.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/toggle_checklist_item.dart';
import 'package:tulap_mobile/features/travel_mission/domain/entities/travel_mission_entity.dart';
import 'package:tulap_mobile/features/travel_mission/domain/repositories/travel_repository.dart';
import 'package:tulap_mobile/features/travel_mission/domain/usecases/add_supporting_document.dart';
import 'package:tulap_mobile/features/travel_mission/domain/usecases/get_travel_mission_detail.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  final AuthUserEntity? user;
  _FakeAuthRepository(this.user);

  @override
  Future<AuthUserEntity?> getStoredUser() async => user;
  @override
  Future<void> logout() async {}
}

class _FakeTaskRepository extends Fake implements TaskRepository {
  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async => const Right([]);
  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async => Right(
    TaskEntity(
      id: taskId,
      taskCode: 'ACT-202608-001',
      taskName: 'Inspeksi Lapangan Mimika',
      destination: 'Jayapura',
      startDate: DateTime(2026, 8, 26),
      endDate: DateTime(2026, 8, 28),
      budgetAmount: 1500000,
      checklistItems: const [],
      status: TaskStatusEntity.verified,
      assigneeId: 'usr_001',
      assigneeName: 'Pak Darto',
      geotagPhotoCount: 2,
      expenseNoteCount: 1,
    ),
  );
  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async => getTaskDetail(taskId);
  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(String taskId) async => getTaskDetail(taskId);
  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({required String taskId, required String itemId, required bool isCompleted}) async => Right(
    ChecklistItemEntity(id: itemId, taskId: taskId, label: 'Item', order: 1, isMandatory: true, isCompleted: isCompleted),
  );
}

class _FakeTravelRepository extends Fake implements TravelRepository {
  @override
  Future<TravelMissionEntity> getTravelMissionDetail(String id, {bool forceRefresh = false}) async => TravelMissionEntity(
    id: id,
    displayId: 'PD-202608-001',
    userId: 'usr_001',
    assignmentLetterNumber: 'ST/001/PU/2026',
    assignmentLetterDate: DateTime(2026, 8, 15),
    title: 'Dinas Luar Kota Mimika',
    purpose: 'Inspeksi',
    origin: 'Jayapura',
    destination: 'Mimika',
    departureDate: DateTime(2026, 8, 20),
    returnDate: DateTime(2026, 8, 24),
    transportMode: TravelTransportMode.pesawat,
    status: TravelMissionStatus.planned,
    budgetEstimate: const TravelBudgetEstimate(
      uangHarian: 1800000,
      penginapan: 2600000,
      transportasi: 1500000,
    ),
    personnelSnapshot: const TravelPersonnelSnapshot(
      fullName: 'Pak Darto',
      employeeNumber: '19740101',
      position: 'Pengawas Jalan',
      unitName: 'Dinas PU Papua',
    ),
    createdAt: DateTime(2026, 8, 15),
  );
  @override
  Future<void> syncTravelMissions() async {}
}

class _FakeGeotagCameraLocalDataSource extends Fake implements GeotagCameraLocalDataSource {
  @override
  Future<List<GeotagPhotoEntity>> getPhotosByTaskId(String taskId) async => [];
}

class _FakeSearchArchiveRepository implements SearchArchiveRepository {
  final List<SearchResultEntity> searchResults;
  final List<RecentSearchEntity> recentSearches;

  _FakeSearchArchiveRepository({
    required this.searchResults,
    required this.recentSearches,
  });

  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  }) async {
    var items = List<SearchResultEntity>.from(searchResults);

    if (filter.selectedType != null) {
      items = items.where((r) => r.entityType == filter.selectedType).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items.where((r) => r.title.toLowerCase().contains(q) || (r.subtitle?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Right(items);
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10}) async {
    return Right(List<RecentSearchEntity>.from(recentSearches));
  }

  @override
  Future<Either<Failure, void>> saveRecentSearch(String query) async {
    recentSearches.insert(
      0,
      RecentSearchEntity(
        id: 'recent_${DateTime.now().millisecondsSinceEpoch}',
        query: query,
        searchedAt: DateTime.now(),
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeRecentSearch(String id) async {
    recentSearches.removeWhere((r) => r.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    recentSearches.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> backfillSearchIndex() async => const Right(5);

  @override
  Future<Either<Failure, void>> rebuildSearchIndex() async => const Right(null);

  @override
  Future<Either<Failure, List<int>>> getAvailableYears() async => const Right([2026, 2025, 2024]);
}

void main() {
  final sl = GetIt.instance;

  final sampleResults = [
    SearchResultEntity(
      entityId: 'act_101',
      entityType: SearchEntityType.activity,
      title: 'Inspeksi Jembatan Mimika',
      subtitle: 'ACT-2026-001 • Kabupaten Mimika',
      date: DateTime(2026, 8, 26),
      location: 'Kabupaten Mimika',
      relevanceScore: 95,
      metadata: const {'status': 'IN_PROGRESS', 'photoCount': 4, 'budgetAmount': '5000000'},
    ),
    SearchResultEntity(
      entityId: 'travel_202',
      entityType: SearchEntityType.travel,
      title: 'Perjalanan Dinas Timika ke Jayapura',
      subtitle: 'PD-2026-002 • Timika → Jayapura',
      date: DateTime(2026, 8, 20),
      location: 'Jayapura',
      relevanceScore: 90,
      metadata: const {'status': 'VERIFIED', 'taskCount': 2},
    ),
    SearchResultEntity(
      entityId: 'photo_303',
      entityType: SearchEntityType.evidence,
      title: 'Foto Kondisi Awal Jembatan',
      subtitle: 'Jl. Trans Papua KM 12',
      date: DateTime(2026, 8, 26, 10, 30),
      location: 'Kabupaten Mimika',
      relevanceScore: 80,
    ),
    SearchResultEntity(
      entityId: 'receipt_404',
      entityType: SearchEntityType.receipt,
      title: 'SPBU Timika Raya',
      subtitle: 'BBM • Rp 350.000',
      date: DateTime(2026, 8, 21),
      location: 'Timika',
      relevanceScore: 85,
      metadata: const {'totalAmount': '350000', 'category': 'BBM'},
    ),
    SearchResultEntity(
      entityId: 'lpj_505',
      entityType: SearchEntityType.lpj,
      title: 'Bundel LPJ Perjalanan Dinas Mimika',
      subtitle: 'LPJ-2026-99 • Versi 1',
      date: DateTime(2026, 8, 27),
      relevanceScore: 92,
      metadata: const {'completenessScore': '100', 'packageCode': 'LPJ-2026-99'},
    ),
  ];

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    await sl.reset();

    final testUser = const AuthUserEntity(
      id: 'usr_001',
      email: 'darto@dinas.go.id',
      fullName: 'Pak Darto',
      role: 'PETUGAS',
      instansiName: 'Dinas PU Papua',
    );

    final fakeAuthRepo = _FakeAuthRepository(testUser);
    final fakeTaskRepo = _FakeTaskRepository();
    final fakeTravelRepo = _FakeTravelRepository();
    final fakeSearchRepo = _FakeSearchArchiveRepository(
      searchResults: sampleResults,
      recentSearches: [
        RecentSearchEntity(
          id: 'rec_1',
          query: 'inspeksi jembatan',
          searchedAt: DateTime.now(),
        ),
        RecentSearchEntity(
          id: 'rec_2',
          query: 'SPBU BBM',
          searchedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    );

    final authManager = AuthSessionManager(authRepository: fakeAuthRepo);
    authManager.updateUser(testUser);
    sl.registerLazySingleton<AuthSessionManager>(() => authManager);

    sl.registerLazySingleton<AuthRepository>(() => fakeAuthRepo);
    sl.registerLazySingleton<GetCurrentSession>(() => GetCurrentSession(fakeAuthRepo));

    sl.registerLazySingleton<TaskRepository>(() => fakeTaskRepo);
    sl.registerLazySingleton<GetTaskDetail>(() => GetTaskDetail(fakeTaskRepo));
    sl.registerLazySingleton<StartTask>(() => StartTask(fakeTaskRepo));
    sl.registerLazySingleton<SubmitTaskForVerification>(() => SubmitTaskForVerification(fakeTaskRepo));
    sl.registerLazySingleton<ToggleChecklistItem>(() => ToggleChecklistItem(fakeTaskRepo));
    sl.registerLazySingleton<GetTaskPhotoPreviews>(() => GetTaskPhotoPreviews(
      _FakeGeotagCameraLocalDataSource(),
    ));

    sl.registerLazySingleton<TravelRepository>(() => fakeTravelRepo);
    sl.registerLazySingleton<GetTravelMissionDetail>(() => GetTravelMissionDetail(fakeTravelRepo));
    sl.registerLazySingleton<AddSupportingDocument>(() => AddSupportingDocument(fakeTravelRepo));

    sl.registerLazySingleton<SearchArchiveRepository>(() => fakeSearchRepo);
    sl.registerLazySingleton<UnifiedSearch>(() => UnifiedSearch(fakeSearchRepo));
    sl.registerLazySingleton<GetRecentSearches>(() => GetRecentSearches(fakeSearchRepo));
    sl.registerLazySingleton<SaveRecentSearch>(() => SaveRecentSearch(fakeSearchRepo));
    sl.registerLazySingleton<ClearRecentSearches>(() => ClearRecentSearches(fakeSearchRepo));
    sl.registerLazySingleton<RebuildSearchIndex>(() => RebuildSearchIndex(fakeSearchRepo));
    sl.registerLazySingleton<GetAvailableYears>(() => GetAvailableYears(fakeSearchRepo));

    sl.registerFactory<SearchArchiveController>(
      () => SearchArchiveController(
        unifiedSearch: sl<UnifiedSearch>(),
        getRecentSearches: sl<GetRecentSearches>(),
        saveRecentSearch: sl<SaveRecentSearch>(),
        clearRecentSearches: sl<ClearRecentSearches>(),
        rebuildSearchIndex: sl<RebuildSearchIndex>(),
        getAvailableYears: sl<GetAvailableYears>(),
      ),
    );
  });

  group('Phase 12: Search & Smart Historical Archiving Integration Tests', () {
    testWidgets('Renders History & Archive page with search bar, chips, and initial items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Arsip & Riwayat'), findsOneWidget);

      // Check Search Bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari kegiatan, lokasi, nota, laporan...'), findsOneWidget);

      // Check Category Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Kegiatan'), findsWidgets);
      expect(find.text('Perjalanan'), findsWidgets);
      expect(find.text('Dokumentasi'), findsWidgets);
      expect(find.text('Nota'), findsWidgets);
      expect(find.text('LPJ'), findsWidgets);

      // Check Recent Searches View
      expect(find.text('Pencarian Terakhir'), findsOneWidget);
      expect(find.text('inspeksi jembatan'), findsOneWidget);
      expect(find.text('SPBU BBM'), findsOneWidget);

      // Check Initial Results
      expect(find.text('Inspeksi Jembatan Mimika'), findsOneWidget);
      expect(find.text('Perjalanan Dinas Timika ke Jayapura'), findsOneWidget);
      expect(find.text('SPBU Timika Raya'), findsOneWidget);
      expect(find.text('Bundel LPJ Perjalanan Dinas Mimika'), findsOneWidget);
    });

    testWidgets('Filtering by Entity Type chip updates results accordingly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Nota' chip inside SearchFilterChips
      final notaChip = find.descendant(
        of: find.byType(SearchFilterChips),
        matching: find.text('Nota'),
      );
      await tester.tap(notaChip);
      await tester.pumpAndSettle();

      // Should only show receipts
      expect(find.text('SPBU Timika Raya'), findsOneWidget);
      expect(find.text('Inspeksi Jembatan Mimika'), findsNothing);
      expect(find.text('Perjalanan Dinas Timika ke Jayapura'), findsNothing);

      // Tap 'Semua' to reset
      final semuaChip = find.descendant(
        of: find.byType(SearchFilterChips),
        matching: find.text('Semua'),
      );
      await tester.tap(semuaChip);
      await tester.pumpAndSettle();

      expect(find.text('Inspeksi Jembatan Mimika'), findsOneWidget);
    });

    testWidgets('Typing in search bar filters results with debounce', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter query 'SPBU'
      await tester.enterText(find.byType(TextField), 'SPBU');
      // Wait for debounce timer (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('SPBU Timika Raya'), findsOneWidget);
      expect(find.text('Inspeksi Jembatan Mimika'), findsNothing);

      // Tap clear icon on search bar
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Results restored
      expect(find.text('Inspeksi Jembatan Mimika'), findsOneWidget);
      expect(find.text('SPBU Timika Raya'), findsOneWidget);
    });

    testWidgets('Tapping a recent search item triggers immediate search', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap recent search chip 'inspeksi jembatan'
      await tester.tap(find.text('inspeksi jembatan'));
      await tester.pumpAndSettle();

      expect(find.text('Inspeksi Jembatan Mimika'), findsOneWidget);
      expect(find.text('SPBU Timika Raya'), findsNothing);
    });

    testWidgets('Opening filter bottom sheet allows changing filters and resets cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Filter button in search header
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Filter Bottom Sheet should open
      expect(find.text('Filter Arsip & Riwayat'), findsOneWidget);
      expect(find.text('Tahun Arsip'), findsOneWidget);
      expect(find.text('Periode Waktu'), findsOneWidget);

      // Tap 'Reset'
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Apply button
      await tester.tap(find.textContaining('Terapkan Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Arsip & Riwayat'), findsOneWidget);
    });

    testWidgets('Rebuild Index button triggers sync snackbar notification', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Rebuild Index icon
      await tester.tap(find.byIcon(Icons.sync_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Indeks arsip pencarian lokal telah diperbarui.'), findsOneWidget);
    });
  });
}
