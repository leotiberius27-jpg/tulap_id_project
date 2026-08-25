import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';

enum HistoryStatus { loading, loaded, error }

/// HistoryFilter
/// ----------------------------------------------------------------------
/// Opsi filter riwayat sesuai Bagian 11.6 spesifikasi produk:
/// - Periode: Hari Ini, Minggu Ini, Bulan Ini
/// - Status: Disetujui, Selesai, Perlu Diperbaiki, Ditolak
/// ----------------------------------------------------------------------
enum HistoryFilter {
  all('Semua'),
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  verified('Disetujui'),
  completed('Selesai'),
  revisionNeeded('Perlu Perbaikan'),
  rejected('Ditolak');

  final String label;
  const HistoryFilter(this.label);
}

class HistoryState {
  final HistoryStatus status;
  final AuthUserEntity? user;
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final HistoryFilter selectedFilter;
  final String searchQuery;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.loading,
    this.user,
    this.allTasks = const [],
    this.filteredTasks = const [],
    this.selectedFilter = HistoryFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  int get totalVerifiedCount => allTasks
      .where(
        (t) =>
            t.status == TaskStatusEntity.verified ||
            t.status == TaskStatusEntity.completed,
      )
      .length;

  int get totalGeotagPhotos =>
      allTasks.fold(0, (sum, t) => sum + t.geotagPhotoCount);

  int get totalExpenseNotes =>
      allTasks.fold(0, (sum, t) => sum + t.expenseNoteCount);

  HistoryState copyWith({
    HistoryStatus? status,
    AuthUserEntity? user,
    List<TaskEntity>? allTasks,
    List<TaskEntity>? filteredTasks,
    HistoryFilter? selectedFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      user: user ?? this.user,
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

/// HistoryController
/// ----------------------------------------------------------------------
/// Mengelola data tab "Riwayat" lengkap dengan pencarian realtime, filter
/// periode (Hari ini, Minggu ini, Bulan ini), filter status, dan metrik
/// dokumentasi bukti.
/// ----------------------------------------------------------------------
class HistoryController extends ChangeNotifier {
  final GetActiveTasks _getActiveTasks;
  final GetCurrentSession _getCurrentSession;

  HistoryState _state = const HistoryState();
  HistoryState get state => _state;

  HistoryController({
    required GetActiveTasks getActiveTasks,
    required GetCurrentSession getCurrentSession,
  }) : _getActiveTasks = getActiveTasks,
       _getCurrentSession = getCurrentSession {
    load();
  }

  void _update(HistoryState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> load() async {
    _update(_state.copyWith(status: HistoryStatus.loading));

    final user = await _getCurrentSession();
    final result = await _getActiveTasks();

    result.fold(
      (failure) => _update(
        _state.copyWith(
          status: HistoryStatus.error,
          user: user,
          errorMessage: failure.message,
        ),
      ),
      (tasks) {
        // Ambil tugas yang sudah tuntas (verified/rejected/completed) atau dalam tahap review/revisi
        final historyPool = tasks
            .where(
              (t) =>
                  t.status.isFinal ||
                  t.status == TaskStatusEntity.revisionNeeded ||
                  t.status == TaskStatusEntity.pendingVerification,
            )
            .toList();

        // Urutkan dari tanggal terbaru
        historyPool.sort((a, b) => b.startDate.compareTo(a.startDate));

        final filtered = _applyFilters(
          historyPool,
          _state.selectedFilter,
          _state.searchQuery,
        );

        _update(
          _state.copyWith(
            status: HistoryStatus.loaded,
            user: user,
            allTasks: historyPool,
            filteredTasks: filtered,
          ),
        );
      },
    );
  }

  void setFilter(HistoryFilter filter) {
    if (_state.selectedFilter == filter) return;
    final filtered = _applyFilters(_state.allTasks, filter, _state.searchQuery);
    _update(_state.copyWith(selectedFilter: filter, filteredTasks: filtered));
  }

  void setSearchQuery(String query) {
    final filtered = _applyFilters(
      _state.allTasks,
      _state.selectedFilter,
      query,
    );
    _update(_state.copyWith(searchQuery: query, filteredTasks: filtered));
  }

  void clearSearch() {
    setSearchQuery('');
  }

  List<TaskEntity> _applyFilters(
    List<TaskEntity> tasks,
    HistoryFilter filter,
    String query,
  ) {
    final now = DateTime.now();

    return tasks.where((task) {
      // 1. Search Query Filter
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = task.taskName.toLowerCase().contains(q);
        final matchCode = task.taskCode.toLowerCase().contains(q);
        final matchDest = task.destination.toLowerCase().contains(q);
        final matchDesc = task.description?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchCode && !matchDest && !matchDesc) {
          return false;
        }
      }

      // 2. Category / Period Filter
      switch (filter) {
        case HistoryFilter.all:
          return true;
        case HistoryFilter.today:
          return task.startDate.year == now.year &&
              task.startDate.month == now.month &&
              task.startDate.day == now.day;
        case HistoryFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final end = start.add(const Duration(days: 7));
          return (task.startDate.isAfter(start) ||
                  task.startDate.isAtSameMomentAs(start)) &&
              task.startDate.isBefore(end);
        case HistoryFilter.thisMonth:
          return task.startDate.year == now.year &&
              task.startDate.month == now.month;
        case HistoryFilter.verified:
          return task.status == TaskStatusEntity.verified;
        case HistoryFilter.completed:
          return task.status == TaskStatusEntity.completed;
        case HistoryFilter.revisionNeeded:
          return task.status == TaskStatusEntity.revisionNeeded;
        case HistoryFilter.rejected:
          return task.status == TaskStatusEntity.rejected;
      }
    }).toList();
  }
}
