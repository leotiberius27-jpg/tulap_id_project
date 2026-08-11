import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure([super.message = 'Tugas tidak ditemukan.']);
}

class TaskSubmitRejectedFailure extends Failure {
  final List<String> incompleteItems;
  TaskSubmitRejectedFailure(this.incompleteItems)
      : super('Masih ada bukti wajib yang belum lengkap.');
}

/// TaskRepositoryImpl
/// ----------------------------------------------------------------------
/// Strategi offline-first untuk getTaskDetail: tampilkan cache lokal
/// SEGERA (tanpa menunggu network), lalu jika online, refresh dari
/// server di background dan update cache - caller (controller) yang
/// memanggil getTaskDetail dua kali (sekali cache, sekali refresh)
/// alih-alih repository ini mencampur keduanya jadi satu response,
/// supaya UI bisa menampilkan data lama sambil memuat data baru
/// tanpa loading spinner yang mem-blok seluruh layar.
/// ----------------------------------------------------------------------
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;
  final TaskRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final EnqueueSyncItem _enqueueSyncItem;

  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    required TaskRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required EnqueueSyncItem enqueueSyncItem,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _enqueueSyncItem = enqueueSyncItem;

  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async {
    final isOnline = await _networkInfo.isConnected;

    if (isOnline) {
      try {
        final remoteTask = await _remoteDataSource.getTaskDetail(taskId);
        await _localDataSource.cacheTask(remoteTask);
        await _localDataSource.cacheChecklistItems(
          remoteTask.checklistItems.map((e) => ChecklistItemModel.fromEntity(e)).toList(),
        );
        // Re-fetch dari cache agar geotagPhotoCount/expenseNoteCount
        // (dihitung dari tabel lokal) ikut terisi konsisten.
        final merged = await _localDataSource.getCachedTask(taskId);
        return Right(merged ?? remoteTask);
      } on DioException {
        // Gagal online meski status konektivitas "terhubung" (mis.
        // server down) - fallback ke cache lokal alih-alih error total.
        return _getFromCacheOrFail(taskId);
      }
    }

    return _getFromCacheOrFail(taskId);
  }

  Future<Either<Failure, TaskEntity>> _getFromCacheOrFail(String taskId) async {
    final cached = await _localDataSource.getCachedTask(taskId);
    if (cached == null) {
      return const Left(TaskNotFoundFailure(
        'Tugas belum tersinkronisasi. Sambungkan ke internet terlebih dahulu.',
      ));
    }
    return Right(cached);
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async {
    try {
      // Update lokal SEGERA (offline-first) - UI tidak menunggu network.
      await _localDataSource.updateChecklistItemLocal(itemId, isCompleted);

      // Daftarkan ke Sync Queue agar perubahan terkirim ke backend saat
      // online, mengikuti pola yang sama persis dengan geotag_camera &
      // expense_ocr.
      await _enqueueSyncItem(
        entityType: SyncEntityType.taskChecklist,
        entityLocalId: itemId,
        taskId: taskId,
      );

      final items = await _localDataSource.getChecklistItems(taskId);
      final updated = items.firstWhere((i) => i.id == itemId);
      return Right(updated);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async {
    try {
      await _remoteDataSource.startTask(taskId);
      return getTaskDetail(taskId);
    } on DioException catch (e) {
      return Left(TaskNotFoundFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(
    String taskId,
  ) async {
    try {
      await _remoteDataSource.submitForVerification(taskId);
      return getTaskDetail(taskId);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (e.response?.statusCode == 400 &&
          responseData is Map &&
          responseData['incompleteItems'] != null) {
        final items = (responseData['incompleteItems'] as List)
            .map((e) => e.toString())
            .toList();
        return Left(TaskSubmitRejectedFailure(items));
      }
      return Left(TaskNotFoundFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async {
    try {
      final tasks = await _remoteDataSource.getTasks();
      return Right(tasks);
    } on DioException catch (e) {
      return Left(TaskNotFoundFailure(_extractErrorMessage(e)));
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
