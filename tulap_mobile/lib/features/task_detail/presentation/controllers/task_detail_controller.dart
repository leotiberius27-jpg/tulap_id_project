import 'package:flutter/foundation.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/start_task.dart';
import '../../domain/usecases/submit_task_for_verification.dart';
import '../../domain/usecases/toggle_checklist_item.dart';

enum TaskDetailStatus { loading, loaded, submitting, error }

class TaskDetailState {
  final TaskDetailStatus status;
  final TaskEntity? task;
  final List<GeotagPhotoEntity> photos;
  final String? errorMessage;
  final List<String>? incompleteItemLabels;

  const TaskDetailState({
    this.status = TaskDetailStatus.loading,
    this.task,
    this.photos = const [],
    this.errorMessage,
    this.incompleteItemLabels,
  });

  TaskDetailState copyWith({
    TaskDetailStatus? status,
    TaskEntity? task,
    List<GeotagPhotoEntity>? photos,
    String? errorMessage,
    List<String>? incompleteItemLabels,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      photos: photos ?? this.photos,
      errorMessage: errorMessage,
      incompleteItemLabels: incompleteItemLabels,
    );
  }
}

/// TaskDetailController
/// ----------------------------------------------------------------------
/// Mengorkestrasi seluruh interaksi di layar Detail Tugas: memuat data,
/// toggle checklist (dengan optimistic update lokal), mulai tugas, dan
/// kirim untuk verifikasi.
/// ----------------------------------------------------------------------
class TaskDetailController extends ChangeNotifier {
  final GetTaskDetail _getTaskDetail;
  final ToggleChecklistItem _toggleChecklistItem;
  final StartTask _startTask;
  final SubmitTaskForVerification _submitForVerification;
  final GetTaskPhotoPreviews _getTaskPhotoPreviews;
  final String taskId;

  TaskDetailState _state = const TaskDetailState();
  TaskDetailState get state => _state;

  TaskDetailController({
    required GetTaskDetail getTaskDetail,
    required ToggleChecklistItem toggleChecklistItem,
    required StartTask startTask,
    required SubmitTaskForVerification submitForVerification,
    required GetTaskPhotoPreviews getTaskPhotoPreviews,
    required this.taskId,
  }) : _getTaskDetail = getTaskDetail,
       _toggleChecklistItem = toggleChecklistItem,
       _startTask = startTask,
       _submitForVerification = submitForVerification,
       _getTaskPhotoPreviews = getTaskPhotoPreviews {
    loadTask();
  }

  void _update(TaskDetailState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadTask() async {
    _update(_state.copyWith(status: TaskDetailStatus.loading));

    final result = await _getTaskDetail(taskId);
    final photosResult = await _getTaskPhotoPreviews(taskId);
    final photos = photosResult.fold(
      (_) => const <GeotagPhotoEntity>[],
      (photos) => photos,
    );

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
        ),
      ),
    );
  }

  /// Optimistic update: UI langsung mencerminkan status baru sebelum
  /// menunggu hasil dari repository - checklist terasa instan bagi
  /// pegawai, sesuai prinsip "less waiting" produk ini. Jika toggle
  /// ternyata gagal (jarang terjadi karena ini operasi lokal), state
  /// dikembalikan ke semula.
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
        // Rollback ke state semula jika gagal - kasus langka karena
        // operasi ini pada dasarnya lokal (SQLite), tapi tetap ditangani.
        _update(_state.copyWith(task: currentTask));
      },
      (_) {}, // Optimistic update sudah benar, tidak perlu aksi tambahan
    );
  }

  /// Dipanggil dari Detail Tugas saat status masih DRAFT dan pegawai
  /// menekan "Mulai Tugas" pertama kali - memindahkan tugas ke ONGOING
  /// di backend (bukan cuma refresh lokal).
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
        return true;
      },
    );
  }

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
        return true;
      },
    );
  }
}
