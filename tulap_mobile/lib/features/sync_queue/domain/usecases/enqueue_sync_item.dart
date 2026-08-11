import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sync_record_entity.dart';
import '../repositories/sync_queue_repository.dart';

/// EnqueueSyncItem (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil oleh fitur lain (geotag_camera, expense_ocr, task_sppd)
/// segera setelah data berhasil disimpan secara lokal. Ini adalah
/// SATU-SATUNYA jalur resmi untuk mendaftarkan pekerjaan yang perlu
/// dikirim ke server - memastikan tidak ada fitur yang "lupa" antre
/// atau mencoba upload langsung tanpa outbox.
/// ----------------------------------------------------------------------
class EnqueueSyncItem {
  final SyncQueueRepository _repository;

  EnqueueSyncItem(this._repository);

  Future<Either<Failure, SyncRecordEntity>> call({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  }) {
    return _repository.enqueue(
      entityType: entityType,
      entityLocalId: entityLocalId,
      taskId: taskId,
    );
  }
}
