import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/entities/search_filter_state.dart';
import '../../domain/entities/recent_search_entity.dart';
import '../../domain/usecases/unified_search.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/save_recent_search.dart';
import '../../domain/usecases/clear_recent_searches.dart';
import '../../domain/usecases/rebuild_search_index.dart';
import '../../domain/usecases/get_available_years.dart';

class SearchArchiveController extends ChangeNotifier {
  final UnifiedSearch unifiedSearch;
  final GetRecentSearches getRecentSearches;
  final SaveRecentSearch saveRecentSearch;
  final ClearRecentSearches clearRecentSearches;
  final RebuildSearchIndex rebuildSearchIndex;
  final GetAvailableYears getAvailableYears;

  SearchArchiveController({
    required this.unifiedSearch,
    required this.getRecentSearches,
    required this.saveRecentSearch,
    required this.clearRecentSearches,
    required this.rebuildSearchIndex,
    required this.getAvailableYears,
  });

  String _query = '';
  SearchFilterState _filter = const SearchFilterState();
  List<SearchResultEntity> _results = [];
  List<RecentSearchEntity> _recentSearches = [];
  List<int> _availableYears = [DateTime.now().year];

  bool _isLoading = false;
  bool _isInitialLoaded = false;
  String? _errorMessage;
  int _requestSequenceId = 0;
  Timer? _debounceTimer;

  String get query => _query;
  SearchFilterState get filter => _filter;
  List<SearchResultEntity> get results => _results;
  List<RecentSearchEntity> get recentSearches => _recentSearches;
  List<int> get availableYears => _availableYears;
  bool get isLoading => _isLoading;
  bool get isInitialLoaded => _isInitialLoaded;
  String? get errorMessage => _errorMessage;

  bool get isQueryEmpty => _query.trim().isEmpty;
  int get resultCount => _results.length;

  Future<void> initialize() async {
    if (_isInitialLoaded) return;
    _isLoading = true;
    notifyListeners();

    // 1. Backfill dan load tahun
    await _loadYears();
    await _loadRecentSearches();

    // 2. Initial archive load (query kosong)
    await _executeSearch(immediate: true);

    _isInitialLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  void onQueryChanged(String newQuery) {
    _query = newQuery;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  void clearQuery() {
    _query = '';
    _debounceTimer?.cancel();
    _executeSearch(immediate: true);
  }

  void applyFilter(SearchFilterState newFilter) {
    _filter = newFilter;
    _executeSearch(immediate: true);
  }

  void selectEntityType(SearchEntityType? type) {
    _filter = _filter.copyWith(selectedType: type, clearType: type == null);
    _executeSearch(immediate: true);
  }

  void selectYear(int? year) {
    _filter = _filter.copyWith(selectedYear: year, clearYear: year == null);
    _executeSearch(immediate: true);
  }

  void selectSortOrder(SearchSortOrder order) {
    _filter = _filter.copyWith(sortOrder: order);
    _executeSearch(immediate: true);
  }

  void resetFilters() {
    _filter = const SearchFilterState();
    _executeSearch(immediate: true);
  }

  Future<void> onRecentSearchTapped(String queryText) async {
    _query = queryText;
    await _executeSearch(immediate: true);
  }

  Future<void> removeRecentSearchItem(String id) async {
    await clearRecentSearches.remove(id);
    await _loadRecentSearches();
    notifyListeners();
  }

  Future<void> clearAllRecentSearches() async {
    await clearRecentSearches();
    _recentSearches = [];
    notifyListeners();
  }

  Future<void> triggerRebuildIndex() async {
    _isLoading = true;
    notifyListeners();
    await rebuildSearchIndex();
    await _loadYears();
    await _executeSearch(immediate: true);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _executeSearch({bool immediate = false}) async {
    final currentReqId = ++_requestSequenceId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simpan ke riwayat jika query memiliki kata kunci
    if (_query.trim().isNotEmpty) {
      unawaited(saveRecentSearch(_query.trim()).then((_) => _loadRecentSearches()));
    }

    final res = await unifiedSearch(
      UnifiedSearchParams(
        query: _query,
        filter: _filter,
      ),
    );

    // Stale Request Protection: Jika ada request baru yang dibuat saat request ini berjalan, abaikan hasil lama!
    if (currentReqId != _requestSequenceId) return;

    res.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _results = data;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadRecentSearches() async {
    final res = await getRecentSearches();
    res.fold((_) {}, (list) {
      _recentSearches = list;
    });
  }

  Future<void> _loadYears() async {
    final res = await getAvailableYears();
    res.fold((_) {}, (years) {
      if (years.isNotEmpty) {
        _availableYears = years;
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
