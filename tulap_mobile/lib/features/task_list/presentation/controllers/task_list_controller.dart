import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';

enum TaskListStatus { loading, loaded, error }

enum TaskListFilter {
  all('Semua'),
  ongoing('Sedang Berjalan'),
  draft('Belum Dimulai'),
  incomplete('Belum Lengkap');

  final String label;
  const TaskListFilter(this.label);
}

class TaskListState {
  final TaskListStatus status;
  final AuthUserEntity? user;
  final List<TaskEntity> allActiveTasks;
  final List<TaskEntity> tasks;
  final TaskListFilter selectedFilter;
  final String? errorMessage;

  const TaskListState({
    this.status = TaskListStatus.loading,
    this.user,
    this.allActiveTasks = const [],
    this.tasks = const [],
    this.selectedFilter = TaskListFilter.all,
    this.errorMessage,
  });

  TaskListState copyWith({
    TaskListStatus? status,
    AuthUserEntity? user,
    List<TaskEntity>? allActiveTasks,
    List<TaskEntity>? tasks,
    TaskListFilter? selectedFilter,
    String? errorMessage,
  }) {
    return TaskListState(
      status: status ?? this.status,
      user: user ?? this.user,
      allActiveTasks: allActiveTasks ?? this.allActiveTasks,
      tasks: tasks ?? this.tasks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: errorMessage,
    );
  }
}

/// TaskListController
/// ----------------------------------------------------------------------
/// Data untuk tab "Tugas" - menampilkan SEMUA tugas AKTIF pegawai,
/// lengkap dengan filter kategori (Semua, Sedang Berjalan, Belum Dimulai, Belum Lengkap).
/// Tugas yang sudah tuntas (verified/rejected/completed) diarahkan ke tab "Riwayat".
/// ----------------------------------------------------------------------
class TaskListController extends ChangeNotifier {
  final GetActiveTasks _getActiveTasks;
  final GetCurrentSession _getCurrentSession;

  TaskListState _state = const TaskListState();
  TaskListState get state => _state;
  bool _isDisposed = false;

  TaskListController({
    required GetActiveTasks getActiveTasks,
    required GetCurrentSession getCurrentSession,
  }) : _getActiveTasks = getActiveTasks,
       _getCurrentSession = getCurrentSession {
    load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _update(TaskListState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void setFilter(TaskListFilter filter) {
    if (_state.selectedFilter == filter) return;
    final filtered = _filterTasks(_state.allActiveTasks, filter);
    _update(_state.copyWith(selectedFilter: filter, tasks: filtered));
  }

  List<TaskEntity> _filterTasks(
    List<TaskEntity> tasks,
    TaskListFilter filter,
  ) {
    switch (filter) {
      case TaskListFilter.all:
        return tasks;
      case TaskListFilter.ongoing:
        return tasks.where((t) => t.status == TaskStatusEntity.ongoing).toList();
      case TaskListFilter.draft:
        return tasks.where((t) => t.status == TaskStatusEntity.draft).toList();
      case TaskListFilter.incomplete:
        return tasks
            .where(
              (t) =>
                  t.status == TaskStatusEntity.revisionNeeded ||
                  (t.status == TaskStatusEntity.ongoing &&
                      (!t.isReadyToSubmit || t.checklistProgress < 1.0)),
            )
            .toList();
    }
  }

  Future<void> load() async {
    _update(_state.copyWith(status: TaskListStatus.loading));

    final user = await _getCurrentSession();
    final result = await _getActiveTasks();

    result.fold(
      (failure) => _update(
        _state.copyWith(
          status: TaskListStatus.error,
          user: user,
          errorMessage: failure.message,
        ),
      ),
      (tasks) {
        final activeList = tasks.where((t) => !t.status.isFinal).toList();
        // Urutkan dari tanggal terbaru
        activeList.sort((a, b) => b.startDate.compareTo(a.startDate));

        final filtered = _filterTasks(activeList, _state.selectedFilter);

        _update(
          _state.copyWith(
            status: TaskListStatus.loaded,
            user: user,
            allActiveTasks: activeList,
            tasks: filtered,
          ),
        );
      },
    );
  }
}
