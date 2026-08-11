import 'package:flutter/foundation.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';

enum HomeStatus { loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final AuthUserEntity? user;
  final TaskEntity? activeTask;
  final bool isOffline;
  final int pendingSyncCount;
  final bool allSynced;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.loading,
    this.user,
    this.activeTask,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.allSynced = false,
    this.errorMessage,
  });
}

/// HomeController
/// ----------------------------------------------------------------------
/// Menyusun data layar Beranda (Bagian 11.1 spesifikasi) dari TIGA
/// sumber berbeda - profil user (auth), tugas aktif (task_detail), dan
/// status antrian sinkronisasi (sync_queue). Karena menggabungkan tiga
/// domain sekaligus, controller ini sengaja tidak "dimiliki" salah satu
/// fitur tsb, melainkan berdiri sendiri di fitur `home` - mengikuti
/// prinsip yang sama seperti SyncCenterController yang langsung
/// mengonsumsi SyncQueueRepository tanpa lapisan domain tambahan.
/// ----------------------------------------------------------------------
class HomeController extends ChangeNotifier {
  final GetCurrentSession _getCurrentSession;
  final GetActiveTasks _getActiveTasks;
  final GetTaskDetail _getTaskDetail;
  final SyncQueueRepository _syncQueueRepository;
  final NetworkInfo _networkInfo;

  HomeState _state = const HomeState();
  HomeState get state => _state;

  HomeController({
    required GetCurrentSession getCurrentSession,
    required GetActiveTasks getActiveTasks,
    required GetTaskDetail getTaskDetail,
    required SyncQueueRepository syncQueueRepository,
    required NetworkInfo networkInfo,
  })  : _getCurrentSession = getCurrentSession,
        _getActiveTasks = getActiveTasks,
        _getTaskDetail = getTaskDetail,
        _syncQueueRepository = syncQueueRepository,
        _networkInfo = networkInfo {
    loadHome();
  }

  void _update(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadHome() async {
    _update(const HomeState(status: HomeStatus.loading));

    final user = await _getCurrentSession();
    final isOnline = await _networkInfo.isConnected;

    TaskEntity? activeTask;
    final tasksResult = await _getActiveTasks();
    await tasksResult.fold(
      (_) async {
        // Gagal memuat daftar tugas (mis. offline) BUKAN error fatal -
        // Beranda tetap tampil dengan kartu tugas aktif kosong, sesuai
        // prinsip "error selalu disertai next action, tidak pernah
        // dead-end" (Bagian 17), bukan layar error total.
        activeTask = null;
      },
      (tasks) async {
        final candidate = _pickActiveTask(tasks);
        if (candidate == null) return;

        final detailResult = await _getTaskDetail(candidate.id);
        activeTask = detailResult.fold((_) => candidate, (detail) => detail);
      },
    );

    final syncResult = await _syncQueueRepository.getAllRecords();
    final records = syncResult.fold(
      (_) => const <SyncRecordEntity>[],
      (records) => records,
    );
    final pendingCount =
        records.where((r) => r.status != SyncStatus.synced).length;

    _update(HomeState(
      status: HomeStatus.loaded,
      user: user,
      activeTask: activeTask,
      isOffline: !isOnline,
      pendingSyncCount: pendingCount,
      allSynced: records.isNotEmpty && pendingCount == 0,
    ));
  }

  /// Memilih SATU tugas untuk ditampilkan di ActiveTaskCard, diprioritaskan
  /// dari yang paling butuh perhatian pegawai: sedang berjalan/perlu
  /// revisi lebih dulu, baru draft, baru yang menunggu verifikator.
  /// Tugas berstatus selesai (VERIFIED/REJECTED/COMPLETED) tidak
  /// dianggap "aktif" lagi.
  TaskEntity? _pickActiveTask(List<TaskEntity> tasks) {
    const priorityOrder = [
      TaskStatusEntity.ongoing,
      TaskStatusEntity.revisionNeeded,
      TaskStatusEntity.draft,
      TaskStatusEntity.pendingVerification,
    ];

    for (final status in priorityOrder) {
      final matches = tasks.where((t) => t.status == status).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (matches.isNotEmpty) return matches.first;
    }

    return null;
  }
}
