import 'package:flutter/foundation.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../../domain/usecases/get_travel_missions.dart';

class TravelMissionListState {
  final bool isLoading;
  final List<TravelMissionEntity> missions;
  final String? errorMessage;
  final String? selectedStatus;
  final int? selectedYear;
  final String searchQuery;

  const TravelMissionListState({
    this.isLoading = false,
    this.missions = const [],
    this.errorMessage,
    this.selectedStatus,
    this.selectedYear,
    this.searchQuery = '',
  });

  TravelMissionListState copyWith({
    bool? isLoading,
    List<TravelMissionEntity>? missions,
    String? errorMessage,
    String? selectedStatus,
    int? selectedYear,
    String? searchQuery,
    bool clearStatus = false,
    bool clearYear = false,
  }) {
    return TravelMissionListState(
      isLoading: isLoading ?? this.isLoading,
      missions: missions ?? this.missions,
      errorMessage: errorMessage,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TravelMissionListController extends ChangeNotifier {
  final GetTravelMissions _getTravelMissions;

  TravelMissionListState _state = const TravelMissionListState();
  TravelMissionListState get state => _state;

  TravelMissionListController({required GetTravelMissions getTravelMissions})
      : _getTravelMissions = getTravelMissions;

  Future<void> loadMissions() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final results = await _getTravelMissions(
        search: _state.searchQuery,
        status: _state.selectedStatus,
        year: _state.selectedYear,
      );
      _state = _state.copyWith(isLoading: false, missions: results);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar perjalanan dinas: $e',
      );
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    loadMissions();
  }

  void setStatusFilter(String? status) {
    _state = _state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    loadMissions();
  }

  void setYearFilter(int? year) {
    _state = _state.copyWith(
      selectedYear: year,
      clearYear: year == null,
    );
    loadMissions();
  }
}
