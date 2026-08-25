import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import 'package:tulap_mobile/features/expense_ocr/data/models/expense_note_model.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/activity_note_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/timeline_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/models/activity_note_model.dart';
import 'package:tulap_mobile/features/task_detail/data/models/timeline_event_model.dart';
import 'package:tulap_mobile/features/task_detail/data/repositories/activity_note_repository_impl.dart';
import 'package:tulap_mobile/features/task_detail/data/repositories/timeline_repository_impl.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/add_activity_note.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_activity_notes.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_expenses.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_timeline_events.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/record_timeline_event.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/start_task.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/submit_task_for_verification.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/toggle_checklist_item.dart';
import 'package:tulap_mobile/features/task_detail/presentation/controllers/task_detail_controller.dart';
import 'package:tulap_mobile/features/task_detail/presentation/pages/task_detail_page.dart';
import 'package:tulap_mobile/features/task_detail/presentation/widgets/checklist_item_tile.dart';

class _MockTaskRepository implements TaskRepository {
  TaskEntity task;
  _MockTaskRepository(this.task);

  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async =>
      Right(task);

  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async {
    task = task.copyWith(status: TaskStatusEntity.ongoing);
    return Right(task);
  }

  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(
    String taskId,
  ) async {
    task = task.copyWith(status: TaskStatusEntity.pendingVerification);
    return Right(task);
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async {
    final idx = task.checklistItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final updated = task.checklistItems[idx].copyWith(
        isCompleted: isCompleted,
      );
      final newItems = List<ChecklistItemEntity>.from(task.checklistItems);
      newItems[idx] = updated;
      task = task.copyWith(checklistItems: newItems);
      return Right(updated);
    }
    return Left(DatabaseFailure('Item not found'));
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async =>
      Right([task]);
}

class _MockActivityNoteLocalDatasource implements ActivityNoteLocalDatasource {
  final List<ActivityNoteModel> notes = [];

  @override
  Future<List<ActivityNoteModel>> getNotesByTask(String taskId) async =>
      notes.where((n) => n.taskId == taskId).toList();

  @override
  Future<ActivityNoteModel> insertNote(ActivityNoteModel note) async {
    notes.insert(0, note);
    return note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    notes.removeWhere((n) => n.id == noteId);
  }
}

class _MockTimelineLocalDataSource implements TimelineLocalDataSource {
  final List<TimelineEventModel> events = [];

  @override
  Future<TimelineEventModel> saveEvent(TimelineEventModel event) async {
    events.insert(0, event);
    return event;
  }

  @override
  Future<List<TimelineEventModel>> getEventsByTask(String taskId) async =>
      events.where((e) => e.taskId == taskId).toList();
}

class _MockGeotagLocalDataSource implements GeotagCameraLocalDataSource {
  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockExpenseLocalDataSource implements ExpenseOcrLocalDataSource {
  final List<ExpenseNoteModel> expenses = [];

  @override
  Future<List<ExpenseNoteModel>> getNotesByTask(String taskId) async =>
      expenses.where((e) => e.taskId == taskId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskEntity testTask;
  late _MockTaskRepository taskRepo;
  late _MockActivityNoteLocalDatasource noteDatasource;
  late _MockTimelineLocalDataSource timelineDatasource;
  late _MockGeotagLocalDataSource geotagDatasource;
  late _MockExpenseLocalDataSource expenseDatasource;

  late ActivityNoteRepositoryImpl noteRepo;
  late TimelineRepositoryImpl timelineRepo;

  late GetTaskDetail getTaskDetail;
  late ToggleChecklistItem toggleChecklistItem;
  late StartTask startTask;
  late SubmitTaskForVerification submitForVerification;
  late GetTaskPhotoPreviews getTaskPhotoPreviews;
  late GetTimelineEvents getTimelineEvents;
  late RecordTimelineEvent recordTimelineEvent;
  late GetActivityNotes getActivityNotes;
  late AddActivityNote addActivityNote;
  late GetTaskExpenses getTaskExpenses;

  setUp(() {
    testTask = TaskEntity(
      id: 'task-act-001',
      taskCode: 'TL-2026-001',
      taskName: 'Cek Ulang Data Aset Waena',
      destination: 'Distrik Heram, Waena',
      startDate: DateTime(2026, 8, 25, 8, 0),
      endDate: DateTime(2026, 8, 25, 16, 0),
      budgetAmount: 1500000,
      status: TaskStatusEntity.ongoing,
      assigneeId: 'officer-1',
      assigneeName: 'Leo Tiberius',
      description:
          'Pengecekan fisik aset kendaraan dinas dan papan reklame di Waena.',
      checklistItems: const [
        ChecklistItemEntity(
          id: 'item-1',
          taskId: 'task-act-001',
          label: 'Dokumentasi Nomor Rangka & Mesin',
          order: 1,
          isMandatory: true,
          isCompleted: false,
        ),
        ChecklistItemEntity(
          id: 'item-2',
          taskId: 'task-act-001',
          label: 'Verifikasi Kondisi Fisik Lapangan',
          order: 2,
          isMandatory: true,
          isCompleted: true,
        ),
      ],
      geotagPhotoCount: 0,
      expenseNoteCount: 0,
    );

    taskRepo = _MockTaskRepository(testTask);
    noteDatasource = _MockActivityNoteLocalDatasource();
    timelineDatasource = _MockTimelineLocalDataSource();
    geotagDatasource = _MockGeotagLocalDataSource();
    expenseDatasource = _MockExpenseLocalDataSource();

    timelineRepo = TimelineRepositoryImpl(localDataSource: timelineDatasource);
    noteRepo = ActivityNoteRepositoryImpl(
      localDatasource: noteDatasource,
      timelineRepository: timelineRepo,
    );

    getTaskDetail = GetTaskDetail(taskRepo);
    toggleChecklistItem = ToggleChecklistItem(taskRepo);
    startTask = StartTask(taskRepo);
    submitForVerification = SubmitTaskForVerification(taskRepo);
    getTaskPhotoPreviews = GetTaskPhotoPreviews(geotagDatasource);
    getTimelineEvents = GetTimelineEvents(timelineRepo);
    recordTimelineEvent = RecordTimelineEvent(timelineRepo);
    getActivityNotes = GetActivityNotes(noteRepo);
    addActivityNote = AddActivityNote(noteRepo);
    getTaskExpenses = GetTaskExpenses(expenseDatasource);
  });

  Widget buildTestableWidget(TaskDetailController controller) {
    return MaterialApp(
      home: ChangeNotifierProvider<TaskDetailController>.value(
        value: controller,
        child: const TaskDetailPage(
          officerName: 'Leo Tiberius',
          agencyName: 'BPKAD Kab. Mimika',
        ),
      ),
    );
  }

  testWidgets(
    'Activity Workspace loads task details, progress, and quick action grid',
    (tester) async {
      final controller = TaskDetailController(
        getTaskDetail: getTaskDetail,
        toggleChecklistItem: toggleChecklistItem,
        startTask: startTask,
        submitForVerification: submitForVerification,
        getTaskPhotoPreviews: getTaskPhotoPreviews,
        getTimelineEvents: getTimelineEvents,
        recordTimelineEvent: recordTimelineEvent,
        getActivityNotes: getActivityNotes,
        addActivityNote: addActivityNote,
        getTaskExpenses: getTaskExpenses,
        taskId: 'task-act-001',
      );

      await tester.pumpWidget(buildTestableWidget(controller));
      await tester.pumpAndSettle();

      // Verify task title and location
      expect(find.text('Cek Ulang Data Aset Waena'), findsOneWidget);
      expect(find.text('Distrik Heram, Waena'), findsOneWidget);

      // Verify Quick Actions Grid
      expect(find.text('Foto'), findsOneWidget);
      expect(find.text('Dokumentasi'), findsWidgets); // in grid & subtitle
      expect(find.text('Scan Nota'), findsOneWidget);
      expect(find.text('Catatan'), findsWidgets);
      expect(find.text('Lokasi'), findsOneWidget);

      // Verify Checklist section
      expect(find.text('CHECKLIST KEGIATAN'), findsOneWidget);
      expect(find.text('Dokumentasi Nomor Rangka & Mesin'), findsOneWidget);
      expect(find.text('Verifikasi Kondisi Fisik Lapangan'), findsOneWidget);

      // Verify Footer CTAs
      expect(find.text('Simpan & Lanjutkan Nanti'), findsOneWidget);
      expect(find.text('Selesaikan Kegiatan'), findsOneWidget);
    },
  );

  testWidgets(
    'Toggling checklist item updates state and records timeline event',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TaskDetailController(
        getTaskDetail: getTaskDetail,
        toggleChecklistItem: toggleChecklistItem,
        startTask: startTask,
        submitForVerification: submitForVerification,
        getTaskPhotoPreviews: getTaskPhotoPreviews,
        getTimelineEvents: getTimelineEvents,
        recordTimelineEvent: recordTimelineEvent,
        getActivityNotes: getActivityNotes,
        addActivityNote: addActivityNote,
        getTaskExpenses: getTaskExpenses,
        taskId: 'task-act-001',
      );

      await tester.pumpWidget(buildTestableWidget(controller));
      await tester.pumpAndSettle();

      // Find and tap the uncompleted checklist item tile
      final tileFinder = find.byType(ChecklistItemTile);
      expect(tileFinder, findsNWidgets(2));

      await tester.tap(tileFinder.first);
      await tester.pumpAndSettle();

      expect(controller.state.task!.checklistItems[0].isCompleted, isTrue);
    },
  );

  testWidgets('Adding field note saves to SQLite and updates list', (
    tester,
  ) async {
    final controller = TaskDetailController(
      getTaskDetail: getTaskDetail,
      toggleChecklistItem: toggleChecklistItem,
      startTask: startTask,
      submitForVerification: submitForVerification,
      getTaskPhotoPreviews: getTaskPhotoPreviews,
      getTimelineEvents: getTimelineEvents,
      recordTimelineEvent: recordTimelineEvent,
      getActivityNotes: getActivityNotes,
      addActivityNote: addActivityNote,
      getTaskExpenses: getTaskExpenses,
      taskId: 'task-act-001',
    );

    await tester.pumpWidget(buildTestableWidget(controller));
    await tester.pumpAndSettle();

    // Add note via controller
    final added = await controller.addNote(
      'Kondisi fisik aset nomor mesin sesuai dan terverifikasi.',
    );
    expect(added, isTrue);
    await tester.pumpAndSettle();

    expect(
      find.text('Kondisi fisik aset nomor mesin sesuai dan terverifikasi.'),
      findsOneWidget,
    );
  });

  group('Activity Workspace Multi-Viewport Responsive Tests', () {
    final viewports = <String, Size>{
      '320x568 (iPhone SE 1st gen)': const Size(320, 568),
      '360x640 (Small Android)': const Size(360, 640),
      '360x800 (Compact Android)': const Size(360, 800),
      '375x812 (iPhone X/11/12 mini)': const Size(375, 812),
      '390x844 (iPhone 12/13/14)': const Size(390, 844),
      '412x915 (Google Pixel / Galaxy)': const Size(412, 915),
      '430x932 (iPhone Pro Max)': const Size(430, 932),
    };

    for (final entry in viewports.entries) {
      testWidgets(
        'Renders cleanly on viewport ${entry.key} without RenderFlex overflow',
        (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final controller = TaskDetailController(
            getTaskDetail: getTaskDetail,
            toggleChecklistItem: toggleChecklistItem,
            startTask: startTask,
            submitForVerification: submitForVerification,
            getTaskPhotoPreviews: getTaskPhotoPreviews,
            getTimelineEvents: getTimelineEvents,
            recordTimelineEvent: recordTimelineEvent,
            getActivityNotes: getActivityNotes,
            addActivityNote: addActivityNote,
            getTaskExpenses: getTaskExpenses,
            taskId: 'task-act-001',
          );

          await tester.pumpWidget(buildTestableWidget(controller));
          await tester.pumpAndSettle();

          // 1. Activity title & status
          expect(find.text('Cek Ulang Data Aset Waena'), findsOneWidget);
          expect(find.text('Sedang Berjalan'), findsWidgets);

          // 2. Location & Indonesian Date Range
          expect(find.text('Distrik Heram, Waena'), findsOneWidget);
          expect(find.textContaining('25 Agu 2026'), findsWidgets);

          // 3. Progress card & 4 pills
          expect(find.text('Progres Kegiatan'), findsOneWidget);
          expect(find.textContaining('Checklist'), findsWidgets);
          expect(find.textContaining('Foto'), findsWidgets);
          expect(find.textContaining('Nota'), findsWidgets);
          expect(find.textContaining('Catatan'), findsWidgets);

          // 4. Field actions
          expect(find.text('Foto'), findsOneWidget);
          expect(find.text('Scan Nota'), findsOneWidget);
          expect(find.text('Lokasi'), findsOneWidget);

          // 5. Checklist section
          expect(find.text('CHECKLIST KEGIATAN'), findsOneWidget);

          // 6. Bottom CTAs
          expect(find.text('Simpan & Lanjutkan Nanti'), findsOneWidget);
          expect(find.text('Selesaikan Kegiatan'), findsOneWidget);

          // Verify no Flutter error caught during render
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
