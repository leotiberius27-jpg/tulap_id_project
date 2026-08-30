import '../../../../core/network/dio_client.dart';
import '../models/task_model.dart';

/// TaskRemoteDataSource
/// ----------------------------------------------------------------------
class TaskRemoteDataSource {
  final DioClient _dioClient;
  TaskRemoteDataSource(this._dioClient);

  Future<TaskModel> getTaskDetail(String taskId) async {
    final taskResponse = await _dioClient.dio.get('/tasks/$taskId');
    final checklistResponse = await _dioClient.dio.get(
      '/tasks/$taskId/checklist',
    );

    final checklistItems = (checklistResponse.data as List)
        .map(
          (json) => ChecklistItemModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();

    return TaskModel.fromApiJson(
      taskResponse.data as Map<String, dynamic>,
      checklistItems: checklistItems,
    );
  }

  Future<ChecklistItemModel> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async {
    final response = await _dioClient.dio.patch(
      '/tasks/$taskId/checklist/$itemId',
      data: {'isCompleted': isCompleted},
    );
    return ChecklistItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> startTask(String taskId) async {
    await _dioClient.dio.post('/tasks/$taskId/start');
  }

  /// GET /tasks dengan dukungan search, filter rentang tanggal, tahun, status, dan paginasi
  Future<List<TaskModel>> getTasks({
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    int? year,
    String? location,
    int? page,
    int? pageSize,
  }) async {
    final response = await _dioClient.dio.get(
      '/tasks',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (year != null) 'year': year,
        if (location != null) 'location': location,
        if (page != null) 'page': page,
        if (pageSize != null) 'pageSize': pageSize,
      },
    );
    final items = (response.data as Map<String, dynamic>)['items'] as List;
    return items
        .map((json) => TaskModel.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /tasks/:id/evidence - Mengambil bukti cloud (foto & nota) untuk kegiatan
  Future<Map<String, dynamic>> getTaskEvidence(String taskId) async {
    final response = await _dioClient.dio.get('/tasks/$taskId/evidence');
    return response.data as Map<String, dynamic>;
  }

  Future<void> submitForVerification(String taskId) async {
    await _dioClient.dio.post('/tasks/$taskId/submit');
  }
}
