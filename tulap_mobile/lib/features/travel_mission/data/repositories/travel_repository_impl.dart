import 'package:uuid/uuid.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/lpj_package_entity.dart';
import '../../domain/entities/supporting_document_entity.dart';
import '../../domain/entities/travel_completeness_result.dart';
import '../../domain/entities/travel_expense_summary.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../../domain/entities/travel_policy_entity.dart';
import '../../domain/repositories/travel_repository.dart';
import '../datasources/travel_local_datasource.dart';
import '../datasources/travel_remote_datasource.dart';
import '../models/supporting_document_model.dart';
import '../models/travel_mission_model.dart';
import '../services/pdf_lpj_package_generator.dart';
import '../services/travel_completeness_service.dart';
import '../services/travel_expense_aggregator.dart';

class TravelRepositoryImpl implements TravelRepository {
  final TravelLocalDatasource _localDatasource;
  final TravelRemoteDatasource? _remoteDatasource;
  final TravelCompletenessService _completenessService;
  final TravelExpenseAggregator _expenseAggregator;
  final PdfLpjPackageGenerator _pdfGenerator;
  final SyncQueueRepository? _syncQueueRepository;

  TravelRepositoryImpl({
    required TravelLocalDatasource localDatasource,
    TravelRemoteDatasource? remoteDatasource,
    TravelCompletenessService? completenessService,
    TravelExpenseAggregator? expenseAggregator,
    PdfLpjPackageGenerator? pdfGenerator,
    SyncQueueRepository? syncQueueRepository,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _completenessService = completenessService ?? TravelCompletenessService(),
        _expenseAggregator = expenseAggregator ?? TravelExpenseAggregator(),
        _pdfGenerator = pdfGenerator ?? PdfLpjPackageGenerator(),
        _syncQueueRepository = syncQueueRepository {
    // Keep reference for future remote sync capabilities
    _remoteDatasource?.toString();
  }

  @override
  Future<TravelMissionEntity> createTravelMission(TravelMissionEntity mission) async {
    final model = TravelMissionModel.fromEntity(mission);
    await _localDatasource.saveTravelMission(model);

    // Enqueue outbox sync record
    final queue = _syncQueueRepository;
    if (queue != null) {
      await queue.enqueue(
        entityType: SyncEntityType.travelMission,
        entityLocalId: model.id,
        taskId: model.id,
      );
    }

    return model;
  }

  @override
  Future<List<TravelMissionEntity>> getTravelMissions({
    String? search,
    String? status,
    int? year,
  }) async {
    return _localDatasource.getTravelMissions(
      search: search,
      status: status,
      year: year,
    );
  }

  @override
  Future<TravelMissionEntity?> getTravelMissionById(String id) async {
    return _localDatasource.getTravelMissionById(id);
  }

  @override
  Future<void> updateTravelMission(TravelMissionEntity mission) async {
    final model = TravelMissionModel.fromEntity(mission);
    await _localDatasource.saveTravelMission(model);

    final queue = _syncQueueRepository;
    if (queue != null) {
      await queue.enqueue(
        entityType: SyncEntityType.travelMission,
        entityLocalId: model.id,
        taskId: model.id,
      );
    }
  }

  @override
  Future<void> completeTravelMission(String id) async {
    await _localDatasource.updateTravelMissionStatus(id, 'completed');
  }

  @override
  Future<void> deleteTravelMission(String id) async {
    await _localDatasource.deleteTravelMission(id);
  }

  @override
  Future<List<TaskEntity>> getTasksByTravelId(String travelId) async {
    return _localDatasource.getTasksByTravelId(travelId);
  }

  @override
  Future<List<ExpenseNoteEntity>> getDirectExpenses(String travelId) async {
    return _localDatasource.getDirectExpensesByTravelId(travelId);
  }

  @override
  Future<List<ExpenseNoteEntity>> getAllExpensesForTravel(
    String travelId,
    List<String> taskIds,
  ) async {
    return _localDatasource.getAllExpensesForTravel(travelId, taskIds);
  }

  @override
  Future<List<GeotagPhotoModel>> getPhotosForTasks(List<String> taskIds) async {
    return _localDatasource.getAllPhotosForTasks(taskIds);
  }

  @override
  Future<SupportingDocumentEntity> addSupportingDocument(
    SupportingDocumentEntity doc,
  ) async {
    final model = SupportingDocumentModel.fromEntity(doc);
    await _localDatasource.saveSupportingDocument(model);

    final queue = _syncQueueRepository;
    if (queue != null) {
      await queue.enqueue(
        entityType: SyncEntityType.supportingDocument,
        entityLocalId: model.id,
        taskId: model.travelMissionId,
      );
    }

    return model;
  }

  @override
  Future<List<SupportingDocumentEntity>> getSupportingDocuments(String travelId) async {
    return _localDatasource.getSupportingDocuments(travelId);
  }

  @override
  Future<void> deleteSupportingDocument(String id) async {
    await _localDatasource.deleteSupportingDocument(id);
  }

  @override
  TravelCompletenessResult evaluateCompleteness({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> allExpenses,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    TravelPolicyEntity policy = TravelPolicyEntity.standard,
  }) {
    final photoWrappers = photos
        .map(
          (p) => GeotagPhotoModelWrapper(
            id: p.id,
            taskId: p.taskId,
            localFilePath: p.localFilePath,
            isVideo: p.isVideo,
          ),
        )
        .toList();

    return _completenessService.evaluateCompleteness(
      travel: travel,
      linkedTasks: linkedTasks,
      directExpenses: directExpenses,
      allExpenses: allExpenses,
      evidencePhotos: photoWrappers,
      supportingDocuments: supportingDocs,
      policy: policy,
    );
  }

  @override
  TravelExpenseSummary aggregateExpenses({
    required TravelMissionEntity travel,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> activityExpenses,
  }) {
    return _expenseAggregator.aggregateExpenses(
      travel: travel,
      directExpenses: directExpenses,
      activityExpenses: activityExpenses,
    );
  }

  @override
  Future<LpjPackageEntity> generateLpjPackage({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required TravelExpenseSummary expenseSummary,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    required TravelCompletenessResult completeness,
  }) async {
    final existingPackages = await _localDatasource.getLpjPackages(travel.id);
    final versionNumber = existingPackages.length + 1;

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final packageCode = 'LPJ-$dateStr-${travel.displayId.split('-').last}';
    final packageId = const Uuid().v4();

    final model = await _pdfGenerator.generateLpjPackagePdf(
      travel: travel,
      linkedTasks: linkedTasks,
      expenseSummary: expenseSummary,
      photos: photos,
      supportingDocs: supportingDocs,
      completeness: completeness,
      packageId: packageId,
      packageCode: packageCode,
      versionNumber: versionNumber,
    );

    await _localDatasource.saveLpjPackage(model);

    // If 100% complete, update travel mission status
    if (completeness.score >= 1.0) {
      await _localDatasource.updateTravelMissionStatus(travel.id, 'lpjReady');
    }

    final queue = _syncQueueRepository;
    if (queue != null) {
      await queue.enqueue(
        entityType: SyncEntityType.lpjPackage,
        entityLocalId: model.id,
        taskId: model.travelMissionId,
      );
    }

    return model;
  }

  @override
  Future<List<LpjPackageEntity>> getLpjPackages(String travelId) async {
    return _localDatasource.getLpjPackages(travelId);
  }

  @override
  Future<LpjPackageEntity?> getLatestLpjPackage(String travelId) async {
    return _localDatasource.getLatestLpjPackage(travelId);
  }
}
