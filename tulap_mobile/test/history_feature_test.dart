import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/history/presentation/controllers/history_controller.dart';
import 'package:tulap_mobile/features/history/presentation/pages/history_page.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      startDate: now.subtract(const Duration(days: 2)), // This week
      endDate: now.subtract(const Duration(days: 1)),
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
      taskName: 'Pengecekan Rambu Lalu Lintas',
      destination: 'Jakarta Selatan',
      startDate: DateTime(2025, 1, 10), // Past year
      endDate: DateTime(2025, 1, 11),
      budgetAmount: 500000,
      status: TaskStatusEntity.rejected,
      latestRevisionNote: 'Lokasi di luar wilayah kerja',
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [],
      geotagPhotoCount: 1,
      expenseNoteCount: 0,
    ),
    TaskEntity(
      id: 'task-draft',
      taskCode: 'TL-202608-0005',
      taskName: 'Tugas Draft Baru',
      destination: 'Depok',
      startDate: now,
      endDate: now,
      budgetAmount: 0,
      status: TaskStatusEntity.draft,
      assigneeId: 'user-001',
      assigneeName: 'Leonardo Petugas',
      checklistItems: const [],
      geotagPhotoCount: 0,
      expenseNoteCount: 0,
    ),
  ];

  group('HistoryController Unit Tests', () {
    test(
      'Initial load filters out drafts and calculates correct summary metrics',
      () async {
        final controller = HistoryController(
          getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
          getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        final state = controller.state;
        expect(state.status, HistoryStatus.loaded);
        expect(state.allTasks.length, 4); // Excludes draft
        expect(
          state.totalVerifiedCount,
          2,
        ); // task-1 (verified) + task-2 (completed)
        expect(state.totalGeotagPhotos, 11); // 3 + 5 + 2 + 1
        expect(state.totalExpenseNotes, 3); // 2 + 1 + 0 + 0
      },
    );

    test('Filter by Period: Today, This Week, This Month', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // 1. Today
      controller.setFilter(HistoryFilter.today);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-1');

      // 2. This Month
      controller.setFilter(HistoryFilter.thisMonth);
      expect(
        controller.state.filteredTasks.length,
        3,
      ); // task-1, task-2, task-3
    });

    test('Filter by Status: Disetujui, Perlu Perbaikan, Ditolak', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      controller.setFilter(HistoryFilter.verified);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.taskCode, 'TL-202608-0001');

      controller.setFilter(HistoryFilter.revisionNeeded);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.taskCode, 'TL-202608-0003');

      controller.setFilter(HistoryFilter.rejected);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.taskCode, 'TL-202608-0004');
    });

    test('Search filter by query: title, task code, destination', () async {
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

      // Search by task code
      controller.setSearchQuery('0004');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-4');

      // Clear search
      controller.clearSearch();
      expect(controller.state.filteredTasks.length, 4);
    });
  });

  group('HistoryPage Widget Tests', () {
    testWidgets(
      'Renders search bar, filter chips, summary metrics, and task cards',
      (tester) async {
        final controller = HistoryController(
          getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
          getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<HistoryController>.value(
              value: controller,
              child: const HistoryPage(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify Header & Search
        expect(find.text('Riwayat Tugas'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Verify Filter Chips
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Hari Ini'), findsOneWidget);
        expect(find.text('Disetujui'), findsWidgets);

        // Verify Summary Metrics
        expect(find.text('Tuntas'), findsOneWidget);
        expect(find.text('Foto Bukti'), findsOneWidget);
        expect(find.text('Nota SPPD'), findsOneWidget);

        // Verify Task Cards
        expect(find.text('Inspeksi Jembatan Ciliwung'), findsOneWidget);
        expect(find.text('TL-202608-0001'), findsOneWidget);
        expect(find.text('3 Foto'), findsOneWidget);
        expect(find.text('2 Nota'), findsOneWidget);
      },
    );

    testWidgets('Tapping a filter chip filters visible items', (tester) async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HistoryController>.value(
            value: controller,
            child: const HistoryPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Hari Ini' filter
      await tester.tap(find.text('Hari Ini'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inspeksi Jembatan Ciliwung'), findsOneWidget);
      expect(find.text('Pemeliharaan Jalan Sudirman'), findsNothing);
    });

    testWidgets('Renders empty search state with Reset Filter button', (
      tester,
    ) async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HistoryController>.value(
            value: controller,
            child: const HistoryPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter query with no match
      await tester.enterText(find.byType(TextField), 'Kota Jayapura');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tidak Ada Hasil'), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);

      // Tap Reset Filter
      await tester.tap(find.text('Reset Filter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inspeksi Jembatan Ciliwung'), findsOneWidget);
    });

    testWidgets('Renders cleanly on multiple screen sizes without overflow', (
      tester,
    ) async {
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

        final controller = HistoryController(
          getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
          getCurrentSession: GetCurrentSession(_FakeAuthRepository(sampleUser)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<HistoryController>.value(
              value: controller,
              child: const HistoryPage(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      }
    });
  });
}
