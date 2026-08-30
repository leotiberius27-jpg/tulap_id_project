import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../entities/lpj_package_entity.dart';
import '../entities/supporting_document_entity.dart';
import '../entities/travel_completeness_result.dart';
import '../entities/travel_expense_summary.dart';
import '../entities/travel_mission_entity.dart';
import '../repositories/travel_repository.dart';

class GenerateLpjPackage {
  final TravelRepository _repository;

  GenerateLpjPackage(this._repository);

  Future<LpjPackageEntity> call({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required TravelExpenseSummary expenseSummary,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    required TravelCompletenessResult completeness,
  }) {
    return _repository.generateLpjPackage(
      travel: travel,
      linkedTasks: linkedTasks,
      expenseSummary: expenseSummary,
      photos: photos,
      supportingDocs: supportingDocs,
      completeness: completeness,
    );
  }
}
