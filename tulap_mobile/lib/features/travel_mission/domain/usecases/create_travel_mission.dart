import '../entities/travel_mission_entity.dart';
import '../repositories/travel_repository.dart';

class CreateTravelMission {
  final TravelRepository _repository;

  CreateTravelMission(this._repository);

  Future<TravelMissionEntity> call(TravelMissionEntity mission) {
    return _repository.createTravelMission(mission);
  }
}
