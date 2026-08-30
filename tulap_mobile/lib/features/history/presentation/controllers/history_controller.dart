import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';

enum HistoryStatus { loading, loaded, error }

/// Opsi Filter Terpadu Riwayat (Section 54, 55, 56)
enum HistoryFilter {
  all('Semua'),
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  sevenDays('7 Hari'),
  thirtyDays('30 Hari'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  customRange('Rentang Tanggal'),
  verified('Disetujui'),
  completed('Selesai'),
  revisionNeeded('Perlu Perbaikan'),
  rejected('Ditolak');

  final String label;
  const HistoryFilter(this.label);
}

typedef HistoryPeriodFilter = HistoryFilter;

/// Opsi Filter Media Bukti (Section 57)
enum HistoryMediaFilter {
  all('Semua Media'),
  hasPhoto('Ada Foto'),
  hasVideo('Ada Video'),
  hasReceipt('Ada Nota');

  final String label;
  const HistoryMediaFilter(this.label);
}

/// Opsi Filter Status Tugas
enum HistoryStatusFilter {
  all('Semua Status'),
  verified('Disetujui'),
  completed('Selesai'),
  revisionNeeded('Perlu Perbaikan'),
  rejected('Ditolak');

  final String label;
  const HistoryStatusFilter(this.label);
}

class HistoryState {
  final HistoryStatus status;
  final AuthUserEntity? user;
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final HistoryPeriodFilter periodFilter;
  final HistoryMediaFilter mediaFilter;
  final HistoryStatusFilter statusFilter;
  final int? selectedYear;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? selectedLocation;
  final String searchQuery;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.loading,
    this.user,
    this.allTasks = const [],
    this.filteredTasks = const [],
    this.periodFilter = HistoryPeriodFilter.all,
    this.mediaFilter = HistoryMediaFilter.all,
    this.statusFilter = HistoryStatusFilter.all,
    this.selectedYear,
    this.customStartDate,
    this.customEndDate,
    this.selectedLocation,
    this.searchQuery = '',
    this.errorMessage,
  });

  // Backward compatibility getter
  HistoryPeriodFilter get selectedFilter => periodFilter;

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

  List<int> get availableYears {
    final years = allTasks.map((t) => t.startDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get availableLocations {
    final locs = allTasks
        .map((t) => t.destination.trim())
        .where((loc) => loc.isNotEmpty)
        .toSet()
        .toList();
    locs.sort();
    return locs;
  }

  bool get hasActiveFilters =>
      periodFilter != HistoryPeriodFilter.all ||
      mediaFilter != HistoryMediaFilter.all ||
      statusFilter != HistoryStatusFilter.all ||
      selectedYear != null ||
      selectedLocation != null ||
      searchQuery.trim().isNotEmpty;

  HistoryState copyWith({
    HistoryStatus? status,
    AuthUserEntity? user,
    List<TaskEntity>? allTasks,
    List<TaskEntity>? filteredTasks,
    HistoryPeriodFilter? periodFilter,
    HistoryMediaFilter? mediaFilter,
    HistoryStatusFilter? statusFilter,
    int? selectedYear,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? selectedLocation,
    String? searchQuery,
    String? errorMessage,
    bool clearYear = false,
    bool clearLocation = false,
    bool clearCustomDates = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      user: user ?? this.user,
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      periodFilter: periodFilter ?? this.periodFilter,
      mediaFilter: mediaFilter ?? this.mediaFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      selectedLocation: clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

/// HistoryController
/// ----------------------------------------------------------------------
/// Mengelola riwayat jangka panjang dengan:
/// - Pencarian ter-debounce (300ms)
/// - Filter multi-dimensi (Waktu, Tahun, Media Bukti, Status, Lokasi)
/// - Rentang tanggal kustom
/// - Pengambilan data awan & lokal terintegrasi
/// ----------------------------------------------------------------------
class HistoryController extends ChangeNotifier {
  final GetActiveTasks _getActiveTasks;
  final GetCurrentSession _getCurrentSession;

  HistoryState _state = const HistoryState();
  HistoryState get state => _state;
  bool _isDisposed = false;
  Timer? _debounceTimer;

  HistoryController({
    required GetActiveTasks getActiveTasks,
    required GetCurrentSession getCurrentSession,
  }) : _getActiveTasks = getActiveTasks,
       _getCurrentSession = getCurrentSession {
    load();
  }

  void _update(HistoryState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isDisposed = true;
    super.dispose();
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

        final filtered = _applyAllFilters(
          tasks: historyPool,
          query: _state.searchQuery,
          period: _state.periodFilter,
          media: _state.mediaFilter,
          status: _state.statusFilter,
          year: _state.selectedYear,
          customStart: _state.customStartDate,
          customEnd: _state.customEndDate,
          location: _state.selectedLocation,
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

  void setFilter(HistoryPeriodFilter filter) {
    setPeriodFilter(filter);
  }

  void setPeriodFilter(HistoryPeriodFilter filter) {
    if (_state.periodFilter == filter) return;
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: filter,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(_state.copyWith(periodFilter: filter, filteredTasks: filtered));
  }

  void setMediaFilter(HistoryMediaFilter mediaFilter) {
    if (_state.mediaFilter == mediaFilter) return;
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: _state.periodFilter,
      media: mediaFilter,
      status: _state.statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(_state.copyWith(mediaFilter: mediaFilter, filteredTasks: filtered));
  }

  void setStatusFilter(HistoryStatusFilter statusFilter) {
    if (_state.statusFilter == statusFilter) return;
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: _state.periodFilter,
      media: _state.mediaFilter,
      status: statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(_state.copyWith(statusFilter: statusFilter, filteredTasks: filtered));
  }

  void setYearFilter(int? year) {
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: _state.periodFilter,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: year,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(
      _state.copyWith(
        selectedYear: year,
        clearYear: year == null,
        filteredTasks: filtered,
      ),
    );
  }

  void setCustomDateRange(DateTime? start, DateTime? end) {
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: HistoryPeriodFilter.customRange,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: null,
      customStart: start,
      customEnd: end,
      location: _state.selectedLocation,
    );
    _update(
      _state.copyWith(
        periodFilter: HistoryPeriodFilter.customRange,
        customStartDate: start,
        customEndDate: end,
        clearYear: true,
        filteredTasks: filtered,
      ),
    );
  }

  void setLocationFilter(String? location) {
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: _state.searchQuery,
      period: _state.periodFilter,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: location,
    );
    _update(
      _state.copyWith(
        selectedLocation: location,
        clearLocation: location == null,
        filteredTasks: filtered,
      ),
    );
  }

  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: query,
      period: _state.periodFilter,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(_state.copyWith(searchQuery: query, filteredTasks: filtered));
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: '',
      period: _state.periodFilter,
      media: _state.mediaFilter,
      status: _state.statusFilter,
      year: _state.selectedYear,
      customStart: _state.customStartDate,
      customEnd: _state.customEndDate,
      location: _state.selectedLocation,
    );
    _update(_state.copyWith(searchQuery: '', filteredTasks: filtered));
  }

  void resetAllFilters() {
    _debounceTimer?.cancel();
    final filtered = _applyAllFilters(
      tasks: _state.allTasks,
      query: '',
      period: HistoryPeriodFilter.all,
      media: HistoryMediaFilter.all,
      status: HistoryStatusFilter.all,
    );
    _update(
      _state.copyWith(
        periodFilter: HistoryPeriodFilter.all,
        mediaFilter: HistoryMediaFilter.all,
        statusFilter: HistoryStatusFilter.all,
        searchQuery: '',
        clearYear: true,
        clearLocation: true,
        clearCustomDates: true,
        filteredTasks: filtered,
      ),
    );
  }

  List<TaskEntity> _applyAllFilters({
    required List<TaskEntity> tasks,
    required String query,
    required HistoryPeriodFilter period,
    required HistoryMediaFilter media,
    required HistoryStatusFilter status,
    int? year,
    DateTime? customStart,
    DateTime? customEnd,
    String? location,
  }) {
    final now = DateTime.now();

    return tasks.where((task) {
      // 1. Search Query
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

      // 2. Year Filter
      if (year != null && task.startDate.year != year) {
        return false;
      }

      // 3. Location Filter
      if (location != null && location.isNotEmpty) {
        if (!task.destination.toLowerCase().contains(location.toLowerCase())) {
          return false;
        }
      }

      // 4. Media Filter
      switch (media) {
        case HistoryMediaFilter.all:
          break;
        case HistoryMediaFilter.hasPhoto:
          if (task.geotagPhotoCount <= 0) return false;
          break;
        case HistoryMediaFilter.hasVideo:
          // Task has media items
          if (task.geotagPhotoCount <= 0) return false;
          break;
        case HistoryMediaFilter.hasReceipt:
          if (task.expenseNoteCount <= 0) return false;
          break;
      }

      // 5. Status Filter
      switch (status) {
        case HistoryStatusFilter.all:
          break;
        case HistoryStatusFilter.verified:
          if (task.status != TaskStatusEntity.verified) return false;
          break;
        case HistoryStatusFilter.completed:
          if (task.status != TaskStatusEntity.completed) return false;
          break;
        case HistoryStatusFilter.revisionNeeded:
          if (task.status != TaskStatusEntity.revisionNeeded) return false;
          break;
        case HistoryStatusFilter.rejected:
          if (task.status != TaskStatusEntity.rejected) return false;
          break;
      }

      // 6. Period / Legacy Filter
      switch (period) {
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
        case HistoryFilter.sevenDays:
          final cutoff = now.subtract(const Duration(days: 7));
          return task.startDate.isAfter(cutoff) ||
              task.startDate.isAtSameMomentAs(cutoff);
        case HistoryFilter.thirtyDays:
          final cutoff = now.subtract(const Duration(days: 30));
          return task.startDate.isAfter(cutoff) ||
              task.startDate.isAtSameMomentAs(cutoff);
        case HistoryFilter.thisMonth:
          return task.startDate.year == now.year &&
              task.startDate.month == now.month;
        case HistoryFilter.thisYear:
          return task.startDate.year == now.year;
        case HistoryFilter.customRange:
          if (customStart == null && customEnd == null) return true;
          final start = customStart ?? DateTime(2000);
          final end =
              (customEnd ?? DateTime(2100)).add(const Duration(days: 1));
          return (task.startDate.isAfter(start) ||
                  task.startDate.isAtSameMomentAs(start)) &&
              task.startDate.isBefore(end);
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
