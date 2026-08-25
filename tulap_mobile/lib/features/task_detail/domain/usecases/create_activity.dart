import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/datasources/timeline_local_datasource.dart';
import '../../data/models/task_model.dart';
import '../../data/models/timeline_event_model.dart';
import '../entities/task_entity.dart';
import '../entities/timeline_event_entity.dart';

/// CreateActivity
/// ----------------------------------------------------------------------
/// Use Case: Membuat dan memulai kegiatan lapangan baru secara mandiri
/// (Mobile-first, Offline-first).
///
/// Alur Eksekusi:
/// 1. Validasi field wajib (nama kegiatan, lokasi, tanggal).
/// 2. Generate ID kegiatan stabil & unik (format: KGL-YYYYMMDD-XXXX).
/// 3. Simpan Task & Checklist ke SQLite lokal terlebih dahulu (status: ongoing).
/// 4. Catat `startedAt` secara otomatis pada saat tombol simpan ditekan.
/// 5. Rekam event awal linimasa (activityStarted).
/// 6. Daftarkan antrean sinkronisasi ke cloud (Outbox pattern).
/// 7. Kembalikan TaskEntity untuk langsung membuka Activity Workspace.
/// ----------------------------------------------------------------------
class CreateActivity {
  final TaskLocalDataSource _localDataSource;
  final TimelineLocalDataSource _timelineDataSource;
  final EnqueueSyncItem _enqueueSyncItem;

  CreateActivity({
    required TaskLocalDataSource localDataSource,
    required TimelineLocalDataSource timelineDataSource,
    required EnqueueSyncItem enqueueSyncItem,
  })  : _localDataSource = localDataSource,
        _timelineDataSource = timelineDataSource,
        _enqueueSyncItem = enqueueSyncItem;

  Future<Either<Failure, TaskEntity>> call({
    required String taskName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double budgetAmount,
    String? description,
    required List<String> checklistLabels,
    AuthUserEntity? currentUser,
  }) async {
    final cleanName = taskName.trim();
    final cleanDest = destination.trim();

    if (cleanName.isEmpty) {
      return Left(ValidationFailure('Nama kegiatan wajib diisi.'));
    }
    if (cleanDest.isEmpty) {
      return Left(ValidationFailure('Lokasi/destinasi kegiatan wajib diisi.'));
    }
    if (endDate.isBefore(startDate)) {
      return Left(
        ValidationFailure('Tanggal selesai tidak boleh mendahului tanggal mulai.'),
      );
    }
    if (checklistLabels.isEmpty) {
      return Left(
        ValidationFailure('Minimal sertakan 1 butir checklist lapangan.'),
      );
    }

    try {
      final taskId = const Uuid().v4();
      final now = DateTime.now();

      // Stable Activity Code: KGL-YYYYMMDD-XXXX
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final shortHex = taskId.replaceAll('-', '').substring(0, 4).toUpperCase();
      final taskCode = 'KGL-$year$month$day-$shortHex';

      // Checklist Models
      final checklistModels = checklistLabels.asMap().entries.map((entry) {
        return ChecklistItemModel(
          id: const Uuid().v4(),
          taskId: taskId,
          label: entry.value.trim(),
          order: entry.key + 1,
          isMandatory: entry.key == 0,
          isCompleted: false,
        );
      }).toList();

      final taskModel = TaskModel(
        id: taskId,
        taskCode: taskCode,
        taskName: cleanName,
        destination: cleanDest,
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        startDate: startDate,
        endDate: endDate,
        budgetAmount: budgetAmount,
        status: TaskStatusEntity.ongoing,
        assigneeId: currentUser?.id ?? 'local-user',
        assigneeName: currentUser?.fullName ?? 'Petugas Lapangan',
        checklistItems: checklistModels,
        geotagPhotoCount: 0,
        expenseNoteCount: 0,
        isSelfCreated: true,
        syncStatus: 'LOCAL_ONLY',
        syncVersion: 1,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Simpan ke SQLite lokal
      await _localDataSource.cacheTask(taskModel);
      await _localDataSource.cacheChecklistItems(checklistModels);

      // 2. Rekam event awal ke linimasa kegiatan
      await _timelineDataSource.saveEvent(
        TimelineEventModel(
          id: const Uuid().v4(),
          taskId: taskId,
          eventType: TimelineEventType.activityStarted,
          title: 'Kegiatan Lapangan Dimulai',
          description: 'Aktivitas lapangan dibuat dan dimulai langsung dari aplikasi mobile',
          eventTimestamp: now,
          syncStatus: 'LOCAL_ONLY',
        ),
      );

      // 3. Masukkan ke outbox antrean sinkronisasi
      try {
        await _enqueueSyncItem(
          entityType: SyncEntityType.taskChecklist,
          entityLocalId: taskId,
          taskId: taskId,
        );
      } catch (_) {
        // Enqueue error non-blocking: data lokal tetap aman
      }

      return Right(taskModel);
    } catch (e) {
      return Left(LocalStorageFailure('Gagal menyimpan kegiatan lokal: $e'));
    }
  }
}
