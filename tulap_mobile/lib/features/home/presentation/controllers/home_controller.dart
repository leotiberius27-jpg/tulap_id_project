import 'package:flutter/foundation.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../domain/home_category.dart';

enum HomeStatus { loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final AuthUserEntity? user;
  final TaskEntity? activeTask;

  /// SEMUA tugas belum final (draft/ongoing/revisionNeeded/pendingVerification)
  /// milik pegawai - sumber data untuk carousel "Aktivitas Berjalan" dan
  /// daftar "Kegiatan Saya", supaya Beranda tidak lagi hanya menyorot SATU
  /// tugas seperti sebelumnya.
  final List<TaskEntity> allActiveTasks;
  final HomeCategory selectedCategory;
  final bool isOffline;
  final int pendingSyncCount;
  final bool allSynced;
  final bool isSyncing;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.loading,
    this.user,
    this.activeTask,
    this.allActiveTasks = const [],
    this.selectedCategory = HomeCategory.semua,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.allSynced = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  /// Tugas yang sedang berjalan atau butuh perbaikan segera - ditampilkan
  /// di carousel "Aktivitas Berjalan" (prioritas tertinggi, lihat juga
  /// `_pickActiveTask`), sudah difilter kategori pill yang aktif.
  List<TaskEntity> get urgentTasks => allActiveTasks
      .where(
        (t) =>
            (t.status == TaskStatusEntity.ongoing ||
                t.status == TaskStatusEntity.revisionNeeded) &&
            _matchesCategory(t),
      )
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// SEMUA tugas belum final, sudah difilter kategori pill yang aktif -
  /// dipakai daftar vertikal "Kegiatan Saya".
  List<TaskEntity> get filteredTasks =>
      allActiveTasks.where(_matchesCategory).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  bool _matchesCategory(TaskEntity task) =>
      selectedCategory == HomeCategory.semua ||
      categorizeTask(task) == selectedCategory;

  HomeState copyWith({
    HomeStatus? status,
    AuthUserEntity? user,
    TaskEntity? activeTask,
    List<TaskEntity>? allActiveTasks,
    HomeCategory? selectedCategory,
    bool? isOffline,
    int? pendingSyncCount,
    bool? allSynced,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      user: user ?? this.user,
      activeTask: activeTask ?? this.activeTask,
      allActiveTasks: allActiveTasks ?? this.allActiveTasks,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isOffline: isOffline ?? this.isOffline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      allSynced: allSynced ?? this.allSynced,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
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
  final BackgroundSyncService _backgroundSyncService;

  HomeState _state = const HomeState();
  HomeState get state => _state;

  HomeController({
    required GetCurrentSession getCurrentSession,
    required GetActiveTasks getActiveTasks,
    required GetTaskDetail getTaskDetail,
    required SyncQueueRepository syncQueueRepository,
    required NetworkInfo networkInfo,
    required BackgroundSyncService backgroundSyncService,
  })  : _getCurrentSession = getCurrentSession,
        _getActiveTasks = getActiveTasks,
        _getTaskDetail = getTaskDetail,
        _syncQueueRepository = syncQueueRepository,
        _networkInfo = networkInfo,
        _backgroundSyncService = backgroundSyncService {
    loadHome();
    // Beranda ikut bereaksi LIVE saat sync otomatis berjalan/selesai di
    // background (Bagian 31/32) - tanpa ini banner "Status Data" bisa
    // basi (menampilkan data lama) sampai user meninggalkan & kembali
    // ke Beranda, walau sync sebenarnya sudah selesai di latar belakang.
    _backgroundSyncService.addListener(_onBackgroundSyncChanged);
  }

  void _onBackgroundSyncChanged() {
    _update(_state.copyWith(isSyncing: _backgroundSyncService.isSyncing));
    // Refresh ringan HANYA field terkait sync (bukan loadHome() penuh -
    // itu akan mereset status ke `loading` dan membuat seluruh Beranda
    // berkedip ke spinner setiap sync otomatis berjalan, sangat
    // mengganggu karena bisa terjadi tiap beberapa menit).
    if (!_backgroundSyncService.isSyncing) {
      _refreshSyncStatus();
    }
  }

  Future<void> _refreshSyncStatus() async {
    final isOnline = await _networkInfo.isConnected;
    final syncResult = await _syncQueueRepository.getAllRecords();
    final records = syncResult.fold(
      (_) => const <SyncRecordEntity>[],
      (records) => records,
    );
    final pendingCount =
        records.where((r) => r.status != SyncStatus.synced).length;

    _update(
      _state.copyWith(
        isOffline: !isOnline,
        pendingSyncCount: pendingCount,
        allSynced: records.isNotEmpty && pendingCount == 0,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundSyncService.removeListener(_onBackgroundSyncChanged);
    super.dispose();
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
    List<TaskEntity> allActiveTasks = const [];
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
        allActiveTasks = tasks;
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
      allActiveTasks: allActiveTasks,
      selectedCategory: _state.selectedCategory,
      isOffline: !isOnline,
      pendingSyncCount: pendingCount,
      allSynced: records.isNotEmpty && pendingCount == 0,
    ));
  }

  /// Ganti pill kategori aktif di Beranda - murni filter lokal terhadap
  /// data yang sudah dimuat, TIDAK memicu fetch ulang ke server/cache.
  void setCategory(HomeCategory category) {
    _update(_state.copyWith(selectedCategory: category));
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
