import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';

enum TaskListStatus { loading, loaded, error }

class TaskListState {
  final TaskListStatus status;
  final AuthUserEntity? user;
  final List<TaskEntity> tasks;
  final String? errorMessage;

  const TaskListState({
    this.status = TaskListStatus.loading,
    this.user,
    this.tasks = const [],
    this.errorMessage,
  });
}

/// TaskListController
/// ----------------------------------------------------------------------
/// Data untuk tab "Tugas" - menampilkan SEMUA tugas AKTIF pegawai (bukan
/// hanya satu prioritas tertinggi seperti Kartu Tugas Aktif di Beranda),
/// sesuai Bagian 21/23 master prompt: "Task List... jika domain/API bisa
/// menyediakan banyak tugas". `GetActiveTasks` sebenarnya mengembalikan
/// SELURUH tugas pegawai tanpa filter status (nama usecase agak
/// menyesatkan) - filter `!isFinal` di sini yang membuat tab ini benar-
/// benar hanya berisi tugas yang masih butuh tindakan; tugas yang sudah
/// tuntas (verified/rejected/completed) ditampilkan di tab "Riwayat"
/// (lihat HistoryController) alih-alih bercampur di sini.
/// ----------------------------------------------------------------------
class TaskListController extends ChangeNotifier {
  final GetActiveTasks _getActiveTasks;
  final GetCurrentSession _getCurrentSession;

  TaskListState _state = const TaskListState();
  TaskListState get state => _state;

  TaskListController({
    required GetActiveTasks getActiveTasks,
    required GetCurrentSession getCurrentSession,
  })  : _getActiveTasks = getActiveTasks,
        _getCurrentSession = getCurrentSession {
    load();
  }

  void _update(TaskListState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> load() async {
    _update(const TaskListState(status: TaskListStatus.loading));

    final user = await _getCurrentSession();
    final result = await _getActiveTasks();

    result.fold(
      (failure) => _update(TaskListState(
        status: TaskListStatus.error,
        user: user,
        errorMessage: failure.message,
      )),
      (tasks) => _update(TaskListState(
        status: TaskListStatus.loaded,
        user: user,
        tasks: tasks.where((t) => !t.status.isFinal).toList(),
      )),
    );
  }
}
