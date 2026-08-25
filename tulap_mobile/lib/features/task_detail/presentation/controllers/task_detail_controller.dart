import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/activity_note_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/usecases/add_activity_note.dart';
import '../../domain/usecases/get_activity_notes.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/get_task_expenses.dart';
import '../../domain/usecases/get_timeline_events.dart';
import '../../domain/usecases/record_timeline_event.dart';
import '../../domain/usecases/start_task.dart';
import '../../domain/usecases/submit_task_for_verification.dart';
import '../../domain/usecases/toggle_checklist_item.dart';

enum TaskDetailStatus { loading, loaded, submitting, error }

class TaskDetailState {
  final TaskDetailStatus status;
  final TaskEntity? task;
  final List<GeotagPhotoEntity> photos;
  final List<ExpenseNoteEntity> expenses;
  final List<ActivityNoteEntity> notes;
  final List<TimelineEventEntity> timelineEvents;
  final int pendingSyncCount;
  final String? errorMessage;
  final List<String>? incompleteItemLabels;

  const TaskDetailState({
    this.status = TaskDetailStatus.loading,
    this.task,
    this.photos = const [],
    this.expenses = const [],
    this.notes = const [],
    this.timelineEvents = const [],
    this.pendingSyncCount = 0,
    this.errorMessage,
    this.incompleteItemLabels,
  });

  double get totalExpenseAmount =>
      expenses.fold(0.0, (sum, item) => sum + item.totalAmount);

  int get totalLocalStoredItems =>
      (task != null ? 1 : 0) +
      photos.length +
      expenses.length +
      notes.length +
      (task?.checklistItems.length ?? 0);

  TaskDetailState copyWith({
    TaskDetailStatus? status,
    TaskEntity? task,
    List<GeotagPhotoEntity>? photos,
    List<ExpenseNoteEntity>? expenses,
    List<ActivityNoteEntity>? notes,
    List<TimelineEventEntity>? timelineEvents,
    int? pendingSyncCount,
    String? errorMessage,
    List<String>? incompleteItemLabels,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      photos: photos ?? this.photos,
      expenses: expenses ?? this.expenses,
      notes: notes ?? this.notes,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: errorMessage,
      incompleteItemLabels: incompleteItemLabels,
    );
  }
}

/// TaskDetailController (Activity Workspace Controller)
/// ----------------------------------------------------------------------
/// Mengorkestrasi seluruh data dan interaksi di layar Activity Workspace:
/// - Memuat detail kegiatan, checklist, galeri bukti foto, daftar nota, catatan lapangan, dan linimasa
/// - Toggle checklist interaktif (optimistic update + simpan SQLite + catat event linimasa)
/// - Tambah Catatan Lapangan (+ simpan SQLite + catat event linimasa)
/// - Selesaikan Kegiatan / Kirim Verifikasi
/// - Cek status sinkronisasi offline-first
/// ----------------------------------------------------------------------
class TaskDetailController extends ChangeNotifier {
  final GetTaskDetail _getTaskDetail;
  final ToggleChecklistItem _toggleChecklistItem;
  final StartTask _startTask;
  final SubmitTaskForVerification _submitForVerification;
  final GetTaskPhotoPreviews _getTaskPhotoPreviews;
  final GetTimelineEvents? _getTimelineEvents;
  final RecordTimelineEvent? _recordTimelineEvent;
  final GetActivityNotes? _getActivityNotes;
  final AddActivityNote? _addActivityNote;
  final GetTaskExpenses? _getTaskExpenses;
  final SyncQueueRepository? _syncQueueRepository;
  final String taskId;

  TaskDetailState _state = const TaskDetailState();
  TaskDetailState get state => _state;

  TaskDetailController({
    required GetTaskDetail getTaskDetail,
    required ToggleChecklistItem toggleChecklistItem,
    required StartTask startTask,
    required SubmitTaskForVerification submitForVerification,
    required GetTaskPhotoPreviews getTaskPhotoPreviews,
    GetTimelineEvents? getTimelineEvents,
    RecordTimelineEvent? recordTimelineEvent,
    GetActivityNotes? getActivityNotes,
    AddActivityNote? addActivityNote,
    GetTaskExpenses? getTaskExpenses,
    SyncQueueRepository? syncQueueRepository,
    required this.taskId,
  }) : _getTaskDetail = getTaskDetail,
       _toggleChecklistItem = toggleChecklistItem,
       _startTask = startTask,
       _submitForVerification = submitForVerification,
       _getTaskPhotoPreviews = getTaskPhotoPreviews,
       _getTimelineEvents =
           getTimelineEvents ??
           (GetIt.instance.isRegistered<GetTimelineEvents>()
               ? GetIt.instance<GetTimelineEvents>()
               : null),
       _recordTimelineEvent =
           recordTimelineEvent ??
           (GetIt.instance.isRegistered<RecordTimelineEvent>()
               ? GetIt.instance<RecordTimelineEvent>()
               : null),
       _getActivityNotes =
           getActivityNotes ??
           (GetIt.instance.isRegistered<GetActivityNotes>()
               ? GetIt.instance<GetActivityNotes>()
               : null),
       _addActivityNote =
           addActivityNote ??
           (GetIt.instance.isRegistered<AddActivityNote>()
               ? GetIt.instance<AddActivityNote>()
               : null),
       _getTaskExpenses =
           getTaskExpenses ??
           (GetIt.instance.isRegistered<GetTaskExpenses>()
               ? GetIt.instance<GetTaskExpenses>()
               : null),
       _syncQueueRepository =
           syncQueueRepository ??
           (GetIt.instance.isRegistered<SyncQueueRepository>()
               ? GetIt.instance<SyncQueueRepository>()
               : null) {
    loadTask();
  }

  bool _isDisposed = false;

  void _update(TaskDetailState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> loadTask() async {
    _update(_state.copyWith(status: TaskDetailStatus.loading));

    // Warm-up lokasi awal di background saat membuka Activity Workspace
    FastLocationService.instance.startWarmUp();

    final result = await _getTaskDetail(taskId);
    final photosResult = await _getTaskPhotoPreviews(taskId);
    final photos = photosResult.fold(
      (_) => const <GeotagPhotoEntity>[],
      (photos) => photos,
    );

    List<ExpenseNoteEntity> expenses = const [];
    if (_getTaskExpenses != null) {
      final expRes = await _getTaskExpenses(taskId);
      expenses = expRes.fold((_) => const [], (list) => list);
    }

    List<ActivityNoteEntity> notes = const [];
    if (_getActivityNotes != null) {
      final noteRes = await _getActivityNotes(taskId);
      notes = noteRes.fold((_) => const [], (list) => list);
    }

    List<TimelineEventEntity> timeline = const [];
    if (_getTimelineEvents != null) {
      final timelineRes = await _getTimelineEvents(taskId);
      timeline = timelineRes.fold((_) => const [], (events) => events);
    }

    int pendingSync = 0;
    if (_syncQueueRepository != null) {
      final queueRes = await _syncQueueRepository.getAllRecords();
      pendingSync = queueRes.fold(
        (_) => 0,
        (records) => records
            .where((r) => r.taskId == taskId && r.status.name != 'synced')
            .length,
      );
    }

    result.fold(
      (failure) => _update(
        TaskDetailState(
          status: TaskDetailStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (task) => _update(
        TaskDetailState(
          status: TaskDetailStatus.loaded,
          task: task,
          photos: photos,
          expenses: expenses,
          notes: notes,
          timelineEvents: timeline,
          pendingSyncCount: pendingSync,
        ),
      ),
    );
  }

  /// Optimistic checklist toggle
  Future<void> toggleItem(String itemId, bool newValue) async {
    final currentTask = _state.task;
    if (currentTask == null) return;

    final optimisticItems = currentTask.checklistItems.map((item) {
      return item.id == itemId ? item.copyWith(isCompleted: newValue) : item;
    }).toList();

    final optimisticTask = TaskEntity(
      id: currentTask.id,
      taskCode: currentTask.taskCode,
      taskName: currentTask.taskName,
      destination: currentTask.destination,
      description: currentTask.description,
      startDate: currentTask.startDate,
      endDate: currentTask.endDate,
      budgetAmount: currentTask.budgetAmount,
      status: currentTask.status,
      assigneeId: currentTask.assigneeId,
      assigneeName: currentTask.assigneeName,
      checklistItems: optimisticItems,
      geotagPhotoCount: currentTask.geotagPhotoCount,
      expenseNoteCount: currentTask.expenseNoteCount,
    );

    _update(_state.copyWith(task: optimisticTask));

    final result = await _toggleChecklistItem(
      taskId: taskId,
      itemId: itemId,
      isCompleted: newValue,
    );

    result.fold(
      (failure) {
        _update(_state.copyWith(task: currentTask));
      },
      (_) async {
        // Rekam event linimasa
        if (_recordTimelineEvent != null) {
          final item = currentTask.checklistItems.firstWhere(
            (i) => i.id == itemId,
            orElse: () => currentTask.checklistItems.first,
          );
          await _recordTimelineEvent(
            taskId: taskId,
            eventType: TimelineEventType.checklistToggled,
            title: newValue ? 'Checklist Diselesaikan' : 'Checklist Dibatalkan',
            description: item.label,
          );
          // Reload linimasa
          if (_getTimelineEvents != null) {
            final timelineRes = await _getTimelineEvents(taskId);
            final timeline = timelineRes.fold(
              (_) => _state.timelineEvents,
              (e) => e,
            );
            _update(_state.copyWith(timelineEvents: timeline));
          }
        }
      },
    );
  }

  /// Tambah Catatan Lapangan
  Future<bool> addNote(String content) async {
    if (_addActivityNote == null || content.trim().isEmpty) return false;

    final result = await _addActivityNote(
      taskId: taskId,
      content: content.trim(),
    );

    return result.fold(
      (failure) {
        _update(_state.copyWith(errorMessage: failure.message));
        return false;
      },
      (savedNote) {
        final updatedNotes = [savedNote, ..._state.notes];
        _update(_state.copyWith(notes: updatedNotes));

        // Reload timeline agar catatan baru langsung muncul di linimasa
        if (_getTimelineEvents != null) {
          _getTimelineEvents(taskId).then((res) {
            res.fold((_) {}, (events) {
              _update(_state.copyWith(timelineEvents: events));
            });
          });
        }
        return true;
      },
    );
  }

  /// Mulai Tugas
  Future<bool> startTask() async {
    final currentTask = _state.task;
    if (currentTask == null) return false;

    _update(_state.copyWith(status: TaskDetailStatus.submitting));

    final result = await _startTask(taskId);

    return result.fold(
      (failure) {
        _update(
          _state.copyWith(
            status: TaskDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (updatedTask) {
        _update(
          _state.copyWith(status: TaskDetailStatus.loaded, task: updatedTask),
        );
        if (_recordTimelineEvent != null) {
          _recordTimelineEvent(
            taskId: taskId,
            eventType: TimelineEventType.activityStarted,
            title: 'Kegiatan Dimulai',
            description: 'Pegawai memulai pelaksanaan tugas di lapangan',
          );
        }
        return true;
      },
    );
  }

  /// Selesaikan Kegiatan / Kirim Verifikasi
  Future<bool> submitForVerification() async {
    final currentTask = _state.task;
    if (currentTask == null) return false;

    _update(_state.copyWith(status: TaskDetailStatus.submitting));

    final result = await _submitForVerification(currentTask);

    return result.fold(
      (failure) {
        List<String>? incompleteLabels;
        if (failure is ChecklistIncompleteFailure) {
          incompleteLabels = currentTask.incompleteMandatoryItems
              .map((i) => i.label)
              .toList();
        }
        _update(
          _state.copyWith(
            status: TaskDetailStatus.loaded,
            task: currentTask,
            errorMessage: failure.message,
            incompleteItemLabels: incompleteLabels,
          ),
        );
        return false;
      },
      (updatedTask) {
        _update(
          _state.copyWith(status: TaskDetailStatus.loaded, task: updatedTask),
        );
        if (_recordTimelineEvent != null) {
          _recordTimelineEvent(
            taskId: taskId,
            eventType: TimelineEventType.activityCompleted,
            title: 'Kegiatan Diselesaikan',
            description: 'Seluruh bukti dan checklist telah rampung dicatat',
          );
        }
        return true;
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    FastLocationService.instance.stopWarmUp();
    super.dispose();
  }
}
