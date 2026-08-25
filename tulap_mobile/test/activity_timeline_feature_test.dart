import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/timeline_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/models/timeline_event_model.dart';
import 'package:tulap_mobile/features/task_detail/data/repositories/timeline_repository_impl.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/timeline_event_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_timeline_events.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/record_timeline_event.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/start_task.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/submit_task_for_verification.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/toggle_checklist_item.dart';
import 'package:tulap_mobile/features/task_detail/presentation/controllers/task_detail_controller.dart';
import 'package:tulap_mobile/features/task_detail/presentation/widgets/activity_timeline_card.dart';

class _FakeTimelineLocalDataSource implements TimelineLocalDataSource {
  final List<TimelineEventModel> items = [];

  @override
  Future<TimelineEventModel> saveEvent(TimelineEventModel event) async {
    items.add(event);
    return event;
  }

  @override
  Future<List<TimelineEventModel>> getEventsByTask(String taskId) async {
    return items.where((e) => e.taskId == taskId).toList();
  }
}

class _FakeTaskRepository implements TaskRepository {
  final TaskEntity task;
  _FakeTaskRepository(this.task);

  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async =>
      Right(task);

  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async =>
      Right(task);

  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(
    String taskId,
  ) async => Right(task);

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async {
    final item = task.checklistItems.firstWhere((i) => i.id == itemId);
    return Right(item.copyWith(isCompleted: isCompleted));
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async =>
      Right([task]);
}

class _FakeGeotagCameraLocalDataSource implements GeotagCameraLocalDataSource {
  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTask = TaskEntity(
    id: 'task-100',
    taskCode: 'TL-202608-0100',
    taskName: 'Survei dan Verifikasi Lapangan Titik Reklame',
    destination: 'Kota Bandung, Jawa Barat',
    startDate: DateTime(2026, 8, 24, 8, 0),
    endDate: DateTime(2026, 8, 24, 17, 0),
    budgetAmount: 500000,
    status: TaskStatusEntity.ongoing,
    assigneeId: 'user-1',
    assigneeName: 'Leonardo',
    checklistItems: const [
      ChecklistItemEntity(
        id: 'c-1',
        taskId: 'task-100',
        label: 'Verifikasi Izin Fisik Reklame',
        order: 1,
        isMandatory: true,
        isCompleted: false,
      ),
    ],
    geotagPhotoCount: 2,
    expenseNoteCount: 1,
  );

  group('Timeline Data & Repository Tests', () {
    test(
      'TimelineEventModel serializes to and from SQLite rows and JSON correctly',
      () {
        final now = DateTime(2026, 8, 24, 9, 30);
        final model = TimelineEventModel(
          id: 'evt-1',
          taskId: 'task-100',
          eventType: TimelineEventType.photoCaptured,
          title: 'Foto Kegiatan Diambil',
          description: 'Bukti foto geotag tersimpan (SHA-256 valid)',
          eventTimestamp: now,
          metadata: const {'latitude': -6.917464, 'longitude': 107.619122},
          syncStatus: 'LOCAL_ONLY',
        );

        final row = model.toRow();
        expect(row['id'], 'evt-1');
        expect(row['eventType'], 'photoCaptured');

        final fromRow = TimelineEventModel.fromRow(row);
        expect(fromRow.id, 'evt-1');
        expect(fromRow.eventType, TimelineEventType.photoCaptured);
        expect(fromRow.metadata?['latitude'], -6.917464);

        final json = model.toJson();
        expect(json['event_type'], 'photoCaptured');
        final fromJson = TimelineEventModel.fromJson(json);
        expect(fromJson.id, 'evt-1');
        expect(fromJson.eventType, TimelineEventType.photoCaptured);
      },
    );

    test(
      'TimelineRepositoryImpl records event and retrieves chronological list',
      () async {
        final fakeDs = _FakeTimelineLocalDataSource();
        final repo = TimelineRepositoryImpl(localDataSource: fakeDs);

        final recRes = await repo.recordEvent(
          taskId: 'task-100',
          eventType: TimelineEventType.activityStarted,
          title: 'Kegiatan Dimulai',
          description: 'Petugas tiba di lokasi',
          timestamp: DateTime(2026, 8, 24, 8, 15),
        );

        expect(recRes.isRight(), isTrue);

        await repo.recordEvent(
          taskId: 'task-100',
          eventType: TimelineEventType.photoCaptured,
          title: 'Dokumentasi Foto #1',
          description: 'Kondisi reklame tampak depan',
          timestamp: DateTime(2026, 8, 24, 8, 30),
        );

        final getRes = await repo.getTimelineEvents('task-100');
        expect(getRes.isRight(), isTrue);
        getRes.fold((_) {}, (events) {
          expect(events.length, 2);
          expect(events.first.eventType, TimelineEventType.activityStarted);
          expect(events.last.eventType, TimelineEventType.photoCaptured);
        });
      },
    );
  });

  group('TaskDetailController with Timeline Integration', () {
    test('Loads task and fetches corresponding timeline events', () async {
      final fakeDs = _FakeTimelineLocalDataSource();
      await fakeDs.saveEvent(
        TimelineEventModel(
          id: 'evt-seed',
          taskId: 'task-100',
          eventType: TimelineEventType.activityStarted,
          title: 'Kegiatan Dimulai',
          eventTimestamp: DateTime(2026, 8, 24, 8, 0),
        ),
      );

      final timelineRepo = TimelineRepositoryImpl(localDataSource: fakeDs);
      final taskRepo = _FakeTaskRepository(sampleTask);

      final controller = TaskDetailController(
        getTaskDetail: GetTaskDetail(taskRepo),
        toggleChecklistItem: ToggleChecklistItem(taskRepo),
        startTask: StartTask(taskRepo),
        submitForVerification: SubmitTaskForVerification(taskRepo),
        getTaskPhotoPreviews: GetTaskPhotoPreviews(
          _FakeGeotagCameraLocalDataSource(),
        ),
        getTimelineEvents: GetTimelineEvents(timelineRepo),
        recordTimelineEvent: RecordTimelineEvent(timelineRepo),
        taskId: 'task-100',
      );

      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state.status, TaskDetailStatus.loaded);
      expect(controller.state.timelineEvents.length, 1);
      expect(controller.state.timelineEvents.first.title, 'Kegiatan Dimulai');
    });
  });

  group('ActivityTimelineCard Widget Tests', () {
    testWidgets('Renders empty state cleanly when no events recorded', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ActivityTimelineCard(events: [])),
        ),
      );

      expect(find.text('Linimasa Kegiatan Otomatis'), findsOneWidget);
    });

    testWidgets(
      'Renders chronological event nodes with formatted time and title',
      (tester) async {
        final events = [
          TimelineEventEntity(
            id: 'e-1',
            taskId: 'task-100',
            eventType: TimelineEventType.activityStarted,
            title: 'Kegiatan Dimulai',
            description: 'Petugas mulai bertugas',
            eventTimestamp: DateTime(2026, 8, 24, 8, 43),
          ),
          TimelineEventEntity(
            id: 'e-2',
            taskId: 'task-100',
            eventType: TimelineEventType.photoCaptured,
            title: 'Foto Kegiatan Diambil',
            description: 'Bukti fisik ber-watermark',
            eventTimestamp: DateTime(2026, 8, 24, 8, 52),
          ),
          TimelineEventEntity(
            id: 'e-3',
            taskId: 'task-100',
            eventType: TimelineEventType.receiptScanned,
            title: 'Nota BBM Rp150.000 Dipindai',
            eventTimestamp: DateTime(2026, 8, 24, 10, 3),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityTimelineCard(events: events)),
          ),
        );

        expect(find.text('LINIMASA KEGIATAN'), findsOneWidget);
        expect(find.text('3 kejadian'), findsOneWidget);
        expect(find.text('Kegiatan Dimulai'), findsOneWidget);
        expect(find.text('Foto Kegiatan Diambil'), findsOneWidget);
        expect(find.text('Nota BBM Rp150.000 Dipindai'), findsOneWidget);
        expect(find.text('08:43'), findsOneWidget);
        expect(find.text('08:52'), findsOneWidget);
        expect(find.text('10:03'), findsOneWidget);
      },
    );
  });
}
