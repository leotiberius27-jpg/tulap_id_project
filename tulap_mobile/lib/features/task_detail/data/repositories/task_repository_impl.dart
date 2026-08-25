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

/// TaskRepositoryImpl
/// ----------------------------------------------------------------------
/// Menghubungkan sumber data remote & local untuk tugas dan checklist.
/// Menerapkan pola offline-first: data lokal selalu tersedia dan
/// disinkronkan ke remote ketika jaringan terhubung.
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
  }) : _localDataSource = localDataSource,
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
          remoteTask.checklistItems
              .map((e) => ChecklistItemModel.fromEntity(e))
              .toList(),
        );
        final merged = await _localDataSource.getCachedTask(taskId);
        return Right(
          (merged ?? remoteTask).withLatestRevisionNote(
            remoteTask.latestRevisionNote,
          ),
        );
      } catch (_) {
        return _getFromCacheOrFail(taskId);
      }
    }

    return _getFromCacheOrFail(taskId);
  }

  Future<Either<Failure, TaskEntity>> _getFromCacheOrFail(String taskId) async {
    final cached = await _localDataSource.getCachedTask(taskId);
    if (cached == null) {
      return const Left(
        TaskNotFoundFailure(
          'Tugas belum tersinkronisasi. Sambungkan ke internet terlebih dahulu.',
        ),
      );
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
      await _localDataSource.updateChecklistItemLocal(itemId, isCompleted);

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
    } catch (_) {
      final cached = await _localDataSource.getCachedTask(taskId);
      if (cached != null) {
        final now = DateTime.now();
        final updated = TaskModel(
          id: cached.id,
          taskCode: cached.taskCode,
          taskName: cached.taskName,
          destination: cached.destination,
          description: cached.description,
          startDate: cached.startDate,
          endDate: cached.endDate,
          budgetAmount: cached.budgetAmount,
          status: TaskStatusEntity.ongoing,
          assigneeId: cached.assigneeId,
          assigneeName: cached.assigneeName,
          checklistItems: cached.checklistItems
              .map((e) => ChecklistItemModel.fromEntity(e))
              .toList(),
          geotagPhotoCount: cached.geotagPhotoCount,
          expenseNoteCount: cached.expenseNoteCount,
          isSelfCreated: cached.isSelfCreated,
          syncStatus: cached.syncStatus,
          syncVersion: cached.syncVersion,
          startedAt: cached.startedAt ?? now,
          completedAt: cached.completedAt,
          createdAt: cached.createdAt,
          updatedAt: now,
        );
        await _localDataSource.cacheTask(updated);
        return Right(updated);
      }
      return const Left(TaskNotFoundFailure('Tugas tidak ditemukan.'));
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
    } catch (_) {
      final cached = await _localDataSource.getCachedTask(taskId);
      if (cached != null) {
        final now = DateTime.now();
        final nextStatus = cached.isSelfCreated
            ? TaskStatusEntity.completed
            : TaskStatusEntity.pendingVerification;

        final updated = TaskModel(
          id: cached.id,
          taskCode: cached.taskCode,
          taskName: cached.taskName,
          destination: cached.destination,
          description: cached.description,
          startDate: cached.startDate,
          endDate: cached.endDate,
          budgetAmount: cached.budgetAmount,
          status: nextStatus,
          assigneeId: cached.assigneeId,
          assigneeName: cached.assigneeName,
          checklistItems: cached.checklistItems
              .map((e) => ChecklistItemModel.fromEntity(e))
              .toList(),
          geotagPhotoCount: cached.geotagPhotoCount,
          expenseNoteCount: cached.expenseNoteCount,
          isSelfCreated: cached.isSelfCreated,
          syncStatus: cached.syncStatus,
          syncVersion: cached.syncVersion,
          startedAt: cached.startedAt,
          completedAt: now,
          createdAt: cached.createdAt,
          updatedAt: now,
        );
        await _localDataSource.cacheTask(updated);
        return Right(updated);
      }
      return const Left(TaskNotFoundFailure('Tugas tidak ditemukan.'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async {
    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      try {
        final tasks = await _remoteDataSource.getTasks();
        for (final t in tasks) {
          await _localDataSource.cacheTask(t);
          await _localDataSource.cacheChecklistItems(
            t.checklistItems
                .map((e) => ChecklistItemModel.fromEntity(e))
                .toList(),
          );
        }
        return Right(tasks);
      } catch (_) {
        final cached = await _localDataSource.getAllCachedTasks();
        return Right(cached);
      }
    }

    final cached = await _localDataSource.getAllCachedTasks();
    return Right(cached);
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Terjadi kesalahan jaringan. Menggunakan data lokal.';
  }
}
