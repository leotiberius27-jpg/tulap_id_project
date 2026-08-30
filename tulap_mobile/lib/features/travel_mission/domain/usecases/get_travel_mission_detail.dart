import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../entities/lpj_package_entity.dart';
import '../entities/supporting_document_entity.dart';
import '../entities/travel_completeness_result.dart';
import '../entities/travel_expense_summary.dart';
import '../entities/travel_mission_entity.dart';
import '../repositories/travel_repository.dart';

class TravelMissionDetailBundle {
  final TravelMissionEntity travel;
  final List<TaskEntity> linkedTasks;
  final List<ExpenseNoteEntity> directExpenses;
  final List<ExpenseNoteEntity> allExpenses;
  final List<GeotagPhotoModel> photos;
  final List<SupportingDocumentEntity> supportingDocuments;
  final TravelExpenseSummary expenseSummary;
  final TravelCompletenessResult completeness;
  final List<LpjPackageEntity> lpjPackages;

  const TravelMissionDetailBundle({
    required this.travel,
    required this.linkedTasks,
    required this.directExpenses,
    required this.allExpenses,
    required this.photos,
    required this.supportingDocuments,
    required this.expenseSummary,
    required this.completeness,
    required this.lpjPackages,
  });
}

class GetTravelMissionDetail {
  final TravelRepository _repository;

  GetTravelMissionDetail(this._repository);

  Future<TravelMissionDetailBundle?> call(String travelId) async {
    final travel = await _repository.getTravelMissionById(travelId);
    if (travel == null) return null;

    final linkedTasks = await _repository.getTasksByTravelId(travelId);
    final taskIds = linkedTasks.map((t) => t.id).toList();

    final directExpenses = await _repository.getDirectExpenses(travelId);
    final allExpenses = await _repository.getAllExpensesForTravel(travelId, taskIds);
    final photos = await _repository.getPhotosForTasks(taskIds);
    final supportingDocuments = await _repository.getSupportingDocuments(travelId);
    final lpjPackages = await _repository.getLpjPackages(travelId);

    final expenseSummary = _repository.aggregateExpenses(
      travel: travel,
      directExpenses: directExpenses,
      activityExpenses: allExpenses.where((e) => e.taskId != travelId && taskIds.contains(e.taskId)).toList(),
    );

    final completeness = _repository.evaluateCompleteness(
      travel: travel,
      linkedTasks: linkedTasks,
      directExpenses: directExpenses,
      allExpenses: allExpenses,
      photos: photos,
      supportingDocs: supportingDocuments,
    );

    return TravelMissionDetailBundle(
      travel: travel,
      linkedTasks: linkedTasks,
      directExpenses: directExpenses,
      allExpenses: allExpenses,
      photos: photos,
      supportingDocuments: supportingDocuments,
      expenseSummary: expenseSummary,
      completeness: completeness,
      lpjPackages: lpjPackages,
    );
  }
}
