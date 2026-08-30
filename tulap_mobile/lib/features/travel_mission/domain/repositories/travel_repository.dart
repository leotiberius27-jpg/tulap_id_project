import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../entities/lpj_package_entity.dart';
import '../entities/supporting_document_entity.dart';
import '../entities/travel_completeness_result.dart';
import '../entities/travel_expense_summary.dart';
import '../entities/travel_mission_entity.dart';
import '../entities/travel_policy_entity.dart';

abstract class TravelRepository {
  Future<TravelMissionEntity> createTravelMission(TravelMissionEntity mission);

  Future<List<TravelMissionEntity>> getTravelMissions({
    String? search,
    String? status,
    int? year,
  });

  Future<TravelMissionEntity?> getTravelMissionById(String id);

  Future<void> updateTravelMission(TravelMissionEntity mission);

  Future<void> completeTravelMission(String id);

  Future<void> deleteTravelMission(String id);

  // Linked Data
  Future<List<TaskEntity>> getTasksByTravelId(String travelId);

  Future<List<ExpenseNoteEntity>> getDirectExpenses(String travelId);

  Future<List<ExpenseNoteEntity>> getAllExpensesForTravel(
    String travelId,
    List<String> taskIds,
  );

  Future<List<GeotagPhotoModel>> getPhotosForTasks(List<String> taskIds);

  // Supporting Documents
  Future<SupportingDocumentEntity> addSupportingDocument(
    SupportingDocumentEntity doc,
  );

  Future<List<SupportingDocumentEntity>> getSupportingDocuments(
    String travelId,
  );

  Future<void> deleteSupportingDocument(String id);

  // LPJ Evaluation & Packages
  TravelCompletenessResult evaluateCompleteness({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> allExpenses,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    TravelPolicyEntity policy = TravelPolicyEntity.standard,
  });

  TravelExpenseSummary aggregateExpenses({
    required TravelMissionEntity travel,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> activityExpenses,
  });

  Future<LpjPackageEntity> generateLpjPackage({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required TravelExpenseSummary expenseSummary,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    required TravelCompletenessResult completeness,
  });

  Future<List<LpjPackageEntity>> getLpjPackages(String travelId);

  Future<LpjPackageEntity?> getLatestLpjPackage(String travelId);
}
