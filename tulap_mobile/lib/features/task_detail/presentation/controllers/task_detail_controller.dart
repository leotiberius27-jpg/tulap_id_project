import 'package:flutter/foundation.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/submit_task_for_verification.dart';
import '../../domain/usecases/toggle_checklist_item.dart';

enum TaskDetailStatus { loading, loaded, submitting, error }

class TaskDetailState {
  final TaskDetailStatus status;
  final TaskEntity? task;
  final String? errorMessage;
  final List<String>? incompleteItemLabels;

  const TaskDetailState({
    this.status = TaskDetailStatus.loading,
    this.task,
    this.errorMessage,
    this.incompleteItemLabels,
  });

  TaskDetailState copyWith({
    TaskDetailStatus? status,
    TaskEntity? task,
    String? errorMessage,
    List<String>? incompleteItemLabels,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
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
  final SubmitTaskForVerification _submitForVerification;
  final String taskId;

  TaskDetailState _state = const TaskDetailState();
  TaskDetailState get state => _state;

  TaskDetailController({
    required GetTaskDetail getTaskDetail,
    required ToggleChecklistItem toggleChecklistItem,
    required SubmitTaskForVerification submitForVerification,
    required this.taskId,
  }) : _getTaskDetail = getTaskDetail,
       _toggleChecklistItem = toggleChecklistItem,
       _submitForVerification = submitForVerification {
    loadTask();
  }

  void _update(TaskDetailState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadTask() async {
    _update(_state.copyWith(status: TaskDetailStatus.loading));

    final result = await _getTaskDetail(taskId);
    result.fold(
      (failure) => _update(
        TaskDetailState(
          status: TaskDetailStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (task) =>
          _update(TaskDetailState(status: TaskDetailStatus.loaded, task: task)),
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

  Future<void> startTask() async {
    // Dipanggil dari Detail Tugas saat status masih DRAFT dan pegawai
    // menekan "Lanjutkan Tugas" pertama kali.
    await loadTask(); // Refresh sederhana - detail startTask ada di repository
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
          TaskDetailState(
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
          TaskDetailState(status: TaskDetailStatus.loaded, task: updatedTask),
        );
        return true;
      },
    );
  }
}
