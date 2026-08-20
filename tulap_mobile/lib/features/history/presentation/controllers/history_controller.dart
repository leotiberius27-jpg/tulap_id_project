import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';

enum HistoryStatus { loading, loaded, error }

class HistoryState {
  final HistoryStatus status;
  final AuthUserEntity? user;
  final List<TaskEntity> tasks;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.loading,
    this.user,
    this.tasks = const [],
    this.errorMessage,
  });
}

/// HistoryController
/// ----------------------------------------------------------------------
/// Data untuk tab "Riwayat" - tugas yang SUDAH TUNTAS (verified/rejected/
/// completed, lihat TaskStatusEntityX.isFinal), pelengkap tab "Tugas"
/// yang sejak perubahan ini hanya berisi tugas aktif. Sengaja memakai
/// USECASE YANG SAMA dengan tab "Tugas" (`GetActiveTasks`, yang
/// sebenarnya mengembalikan seluruh tugas pegawai tanpa filter status)
/// alih-alih endpoint/usecase baru - tidak ada data yang direkayasa,
/// murni memilah data yang sudah ada. TIDAK menampilkan riwayat
/// aktivitas granular (per-foto/per-nota/per-sync) - itu butuh audit
/// trail di level backend yang belum ada, lihat catatan di HistoryPage.
/// ----------------------------------------------------------------------
class HistoryController extends ChangeNotifier {
  final GetActiveTasks _getActiveTasks;
  final GetCurrentSession _getCurrentSession;

  HistoryState _state = const HistoryState();
  HistoryState get state => _state;

  HistoryController({
    required GetActiveTasks getActiveTasks,
    required GetCurrentSession getCurrentSession,
  })  : _getActiveTasks = getActiveTasks,
        _getCurrentSession = getCurrentSession {
    load();
  }

  void _update(HistoryState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> load() async {
    _update(const HistoryState(status: HistoryStatus.loading));

    final user = await _getCurrentSession();
    final result = await _getActiveTasks();

    result.fold(
      (failure) => _update(HistoryState(
        status: HistoryStatus.error,
        user: user,
        errorMessage: failure.message,
      )),
      (tasks) => _update(HistoryState(
        status: HistoryStatus.loaded,
        user: user,
        tasks: tasks.where((t) => t.status.isFinal).toList(),
      )),
    );
  }
}
