import 'search_result_entity.dart';

enum SearchSortOrder {
  relevance('Paling Relevan'),
  newest('Terbaru'),
  oldest('Terlama');

  final String label;
  const SearchSortOrder(this.label);
}

enum QuickDateFilter {
  all('Semua'),
  today('Hari Ini'),
  last7Days('7 Hari Terakhir'),
  last30Days('30 Hari Terakhir'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  custom('Pilih Tanggal');

  final String label;
  const QuickDateFilter(this.label);
}

class SearchFilterState {
  final SearchEntityType? selectedType;
  final QuickDateFilter quickDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? selectedYear;
  final String? location;
  final String? status;
  final String? expenseCategory;
  final String? syncStatus;
  final SearchSortOrder sortOrder;

  const SearchFilterState({
    this.selectedType,
    this.quickDate = QuickDateFilter.all,
    this.startDate,
    this.endDate,
    this.selectedYear,
    this.location,
    this.status,
    this.expenseCategory,
    this.syncStatus,
    this.sortOrder = SearchSortOrder.relevance,
  });

  bool get hasActiveFilters =>
      selectedType != null ||
      quickDate != QuickDateFilter.all ||
      startDate != null ||
      endDate != null ||
      selectedYear != null ||
      (location != null && location!.isNotEmpty) ||
      (status != null && status!.isNotEmpty) ||
      (expenseCategory != null && expenseCategory!.isNotEmpty) ||
      (syncStatus != null && syncStatus!.isNotEmpty);

  int get activeFilterCount {
    int count = 0;
    if (selectedType != null) count++;
    if (quickDate != QuickDateFilter.all || startDate != null || endDate != null) count++;
    if (selectedYear != null) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (expenseCategory != null && expenseCategory!.isNotEmpty) count++;
    if (syncStatus != null && syncStatus!.isNotEmpty) count++;
    return count;
  }

  SearchFilterState copyWith({
    SearchEntityType? selectedType,
    bool clearType = false,
    QuickDateFilter? quickDate,
    DateTime? startDate,
    bool clearDates = false,
    DateTime? endDate,
    int? selectedYear,
    bool clearYear = false,
    String? location,
    bool clearLocation = false,
    String? status,
    bool clearStatus = false,
    String? expenseCategory,
    bool clearCategory = false,
    String? syncStatus,
    bool clearSyncStatus = false,
    SearchSortOrder? sortOrder,
  }) {
    return SearchFilterState(
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      quickDate: quickDate ?? this.quickDate,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      location: clearLocation ? null : (location ?? this.location),
      status: clearStatus ? null : (status ?? this.status),
      expenseCategory: clearCategory ? null : (expenseCategory ?? this.expenseCategory),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
