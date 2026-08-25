import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/usecases/enqueue_sync_item.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/task_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/timeline_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/models/task_model.dart';
import 'package:tulap_mobile/features/task_detail/data/models/timeline_event_model.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/create_activity.dart';
import 'package:tulap_mobile/features/task_list/presentation/controllers/task_list_controller.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';

class FakeTaskLocalDataSource implements TaskLocalDataSource {
  TaskModel? cachedTask;
  List<ChecklistItemModel>? cachedChecklist;

  @override
  Future<void> cacheTask(TaskModel task) async {
    cachedTask = task;
  }

  @override
  Future<void> cacheChecklistItems(List<ChecklistItemModel> items) async {
    cachedChecklist = items;
  }

  @override
  Future<TaskModel?> getCachedTask(String taskId) async => cachedTask;

  @override
  Future<List<TaskModel>> getAllCachedTasks() async => cachedTask != null ? [cachedTask!] : [];

  @override
  Future<List<ChecklistItemModel>> getChecklistItems(String taskId) async => cachedChecklist ?? [];

  @override
  Future<void> updateChecklistItemLocal(String itemId, bool isCompleted) async {}
}

class FakeTimelineLocalDataSource implements TimelineLocalDataSource {
  TimelineEventModel? savedEvent;

  @override
  Future<TimelineEventModel> saveEvent(TimelineEventModel event) async {
    savedEvent = event;
    return event;
  }

  @override
  Future<List<TimelineEventModel>> getEventsByTask(String taskId) async =>
      savedEvent != null ? [savedEvent!] : [];
}

class FakeEnqueueSyncItem extends Fake implements EnqueueSyncItem {
  SyncEntityType? lastEntityType;
  String? lastLocalId;

  @override
  Future<Either<Failure, SyncRecordEntity>> call({
    required SyncEntityType entityType,
    required String entityLocalId,
    String? taskId,
  }) async {
    lastEntityType = entityType;
    lastLocalId = entityLocalId;
    return Right(SyncRecordEntity(
      id: 'sync-1',
      entityType: entityType,
      entityLocalId: entityLocalId,
      taskId: taskId ?? '',
      status: SyncStatus.pendingUpload,
      attemptCount: 0,
      createdAt: DateTime.now(),
    ));
  }
}

class FakeGetActiveTasks extends Fake implements GetActiveTasks {
  final List<TaskEntity> tasks;
  FakeGetActiveTasks(this.tasks);

  @override
  Future<Either<Failure, List<TaskEntity>>> call() async {
    return Right(tasks);
  }
}

class FakeGetCurrentSession extends Fake implements GetCurrentSession {
  final AuthUserEntity? user;
  FakeGetCurrentSession(this.user);

  @override
  Future<AuthUserEntity?> call() async => user;
}

void main() {
  late FakeTaskLocalDataSource fakeLocalDs;
  late FakeTimelineLocalDataSource fakeTimelineDs;
  late FakeEnqueueSyncItem fakeEnqueueSync;
  late CreateActivity createActivity;

  final testUser = const AuthUserEntity(
    id: 'usr-123',
    email: 'petugas@tulap.id',
    fullName: 'Petugas Uji',
    role: 'surveyor',
    instansiName: 'BPKAD Kota',
  );

  setUp(() {
    fakeLocalDs = FakeTaskLocalDataSource();
    fakeTimelineDs = FakeTimelineLocalDataSource();
    fakeEnqueueSync = FakeEnqueueSyncItem();
    createActivity = CreateActivity(
      localDataSource: fakeLocalDs,
      timelineDataSource: fakeTimelineDs,
      enqueueSyncItem: fakeEnqueueSync,
    );
  });

  group('CreateActivity Use Case Tests', () {
    test('Fails when activity name is empty', () async {
      final result = await createActivity(
        taskName: '   ',
        destination: 'Lokasi Uji',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        budgetAmount: 100000,
        checklistLabels: ['Checklist 1'],
        currentUser: testUser,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Nama kegiatan wajib diisi.'),
        (_) => fail('Should not succeed'),
      );
    });

    test('Fails when destination is empty', () async {
      final result = await createActivity(
        taskName: 'Nama Kegiatan',
        destination: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        budgetAmount: 100000,
        checklistLabels: ['Checklist 1'],
        currentUser: testUser,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Lokasi/destinasi kegiatan wajib diisi.'),
        (_) => fail('Should not succeed'),
      );
    });

    test('Fails when endDate is before startDate', () async {
      final now = DateTime.now();
      final result = await createActivity(
        taskName: 'Nama Kegiatan',
        destination: 'Lokasi Uji',
        startDate: now,
        endDate: now.subtract(const Duration(days: 1)),
        budgetAmount: 100000,
        checklistLabels: ['Checklist 1'],
        currentUser: testUser,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Tanggal selesai tidak boleh mendahului tanggal mulai.'),
        (_) => fail('Should not succeed'),
      );
    });

    test('Successfully creates activity, generates stable code, sets ongoing status and startedAt', () async {
      final start = DateTime(2026, 8, 25, 9, 0);
      final end = DateTime(2026, 8, 25, 17, 0);

      final result = await createActivity(
        taskName: 'Pemeriksaan Lapangan BMD',
        destination: 'Jl. Pemuda No. 10',
        startDate: start,
        endDate: end,
        budgetAmount: 250000,
        description: 'Pemeriksaan fisik aset daerah',
        checklistLabels: [
          'Verifikasi Koordinat',
          'Dokumentasi Foto',
        ],
        currentUser: testUser,
      );

      expect(result.isRight(), isTrue);
      final task = result.getOrElse(() => throw Exception());

      expect(task.taskName, 'Pemeriksaan Lapangan BMD');
      expect(task.destination, 'Jl. Pemuda No. 10');
      expect(task.status, TaskStatusEntity.ongoing);
      expect(task.isSelfCreated, isTrue);
      expect(task.taskCode.startsWith('KGL-'), isTrue);
      expect(task.startedAt, isNotNull);
      expect(task.checklistItems.length, 2);
      expect(task.checklistItems.first.isMandatory, isTrue);
      expect(task.assigneeId, 'usr-123');
      expect(task.assigneeName, 'Petugas Uji');

      expect(fakeLocalDs.cachedTask, isNotNull);
      expect(fakeLocalDs.cachedChecklist?.length, 2);
      expect(fakeTimelineDs.savedEvent, isNotNull);
      expect(fakeEnqueueSync.lastLocalId, task.id);
    });
  });

  group('TaskListController Filter Tests', () {
    final now = DateTime.now();
    final task1Ongoing = TaskEntity(
      id: 't-1',
      taskCode: 'KGL-001',
      taskName: 'Kegiatan 1',
      destination: 'Lokasi 1',
      startDate: now,
      endDate: now,
      budgetAmount: 100000,
      status: TaskStatusEntity.ongoing,
      assigneeId: 'usr-1',
      assigneeName: 'Petugas',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'c1',
          taskId: 't-1',
          label: 'Item 1',
          order: 1,
          isMandatory: true,
          isCompleted: true,
        ),
      ],
      geotagPhotoCount: 2,
      expenseNoteCount: 1,
      syncStatus: 'SYNCED',
    );

    final task2Draft = TaskEntity(
      id: 't-2',
      taskCode: 'KGL-002',
      taskName: 'Kegiatan 2',
      destination: 'Lokasi 2',
      startDate: now.add(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
      budgetAmount: 200000,
      status: TaskStatusEntity.draft,
      assigneeId: 'usr-1',
      assigneeName: 'Petugas',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'c2',
          taskId: 't-2',
          label: 'Item 2',
          order: 1,
          isMandatory: false,
          isCompleted: false,
        ),
      ],
      geotagPhotoCount: 0,
      expenseNoteCount: 0,
      syncStatus: 'LOCAL_ONLY',
    );

    final task3Revision = TaskEntity(
      id: 't-3',
      taskCode: 'KGL-003',
      taskName: 'Kegiatan 3',
      destination: 'Lokasi 3',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.subtract(const Duration(days: 1)),
      budgetAmount: 300000,
      status: TaskStatusEntity.revisionNeeded,
      assigneeId: 'usr-1',
      assigneeName: 'Petugas',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'c3',
          taskId: 't-3',
          label: 'Item 3',
          order: 1,
          isMandatory: false,
          isCompleted: false,
        ),
      ],
      geotagPhotoCount: 1,
      expenseNoteCount: 0,
      syncStatus: 'SYNCED',
      latestRevisionNote: 'Foto kurang jelas',
    );

    test('Filter "all" returns all 3 tasks', () async {
      final controller = TaskListController(
        getActiveTasks: FakeGetActiveTasks([task1Ongoing, task2Draft, task3Revision]),
        getCurrentSession: FakeGetCurrentSession(testUser),
      );

      await controller.load();

      controller.setFilter(TaskListFilter.all);
      expect(controller.state.tasks.length, 3);
    });

    test('Filter "ongoing" returns only ongoing tasks', () async {
      final controller = TaskListController(
        getActiveTasks: FakeGetActiveTasks([task1Ongoing, task2Draft, task3Revision]),
        getCurrentSession: FakeGetCurrentSession(testUser),
      );

      await controller.load();

      controller.setFilter(TaskListFilter.ongoing);
      expect(controller.state.tasks.length, 1);
      expect(controller.state.tasks.first.id, 't-1');
    });

    test('Filter "draft" returns only draft/not-started tasks', () async {
      final controller = TaskListController(
        getActiveTasks: FakeGetActiveTasks([task1Ongoing, task2Draft, task3Revision]),
        getCurrentSession: FakeGetCurrentSession(testUser),
      );

      await controller.load();

      controller.setFilter(TaskListFilter.draft);
      expect(controller.state.tasks.length, 1);
      expect(controller.state.tasks.first.id, 't-2');
    });

    test('Filter "incomplete" returns revisionNeeded tasks', () async {
      final controller = TaskListController(
        getActiveTasks: FakeGetActiveTasks([task1Ongoing, task2Draft, task3Revision]),
        getCurrentSession: FakeGetCurrentSession(testUser),
      );

      await controller.load();

      controller.setFilter(TaskListFilter.incomplete);
      expect(controller.state.tasks.length, 1);
      expect(controller.state.tasks.first.id, 't-3');
    });
  });
}
