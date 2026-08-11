import '../../../../core/network/dio_client.dart';
import '../models/task_model.dart';

/// TaskRemoteDataSource
/// ----------------------------------------------------------------------
class TaskRemoteDataSource {
  final DioClient _dioClient;
  TaskRemoteDataSource(this._dioClient);

  Future<TaskModel> getTaskDetail(String taskId) async {
    final taskResponse = await _dioClient.dio.get('/tasks/$taskId');
    final checklistResponse =
        await _dioClient.dio.get('/tasks/$taskId/checklist');

    final checklistItems = (checklistResponse.data as List)
        .map((json) => ChecklistItemModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Jumlah foto/nota TIDAK disertakan langsung di response backend
    // saat ini (endpoint GET /evidence/by-task belum dibangun) - untuk
    // sementara dihitung dari cache lokal saja di repository, bukan
    // dari server. Lihat catatan di TaskRepositoryImpl.
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

  /// Melempar DioException dengan response.data berisi
  /// { message, incompleteItems } jika backend menolak karena checklist
  /// belum lengkap (lihat TasksService.submitForVerification di
  /// backend) - repository menerjemahkan ini jadi Failure yang sesuai.
  Future<void> submitForVerification(String taskId) async {
    await _dioClient.dio.post('/tasks/$taskId/submit');
  }
}
