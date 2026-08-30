import '../entities/travel_mission_entity.dart';
import '../repositories/travel_repository.dart';

class GetTravelMissions {
  final TravelRepository _repository;

  GetTravelMissions(this._repository);

  Future<List<TravelMissionEntity>> call({
    String? search,
    String? status,
    int? year,
  }) {
    return _repository.getTravelMissions(
      search: search,
      status: status,
      year: year,
    );
  }
}
