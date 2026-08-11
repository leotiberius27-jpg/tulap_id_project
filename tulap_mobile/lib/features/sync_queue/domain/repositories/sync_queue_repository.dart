import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sync_record_entity.dart';

/// SyncQueueRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class SyncQueueRepository {
  /// Mendaftarkan satu unit kerja baru ke antrian outbox. Dipanggil
  /// oleh fitur lain (mis. geotag_camera setelah foto tersimpan lokal)
  /// - fitur lain TIDAK PERNAH berbicara langsung ke API, selalu lewat
  /// antrian ini demi konsistensi penanganan offline.
  Future<Either<Failure, SyncRecordEntity>> enqueue({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  });

  /// Mengambil seluruh antrian untuk ditampilkan di Sync Center.
  Future<Either<Failure, List<SyncRecordEntity>>> getAllRecords();

  /// Memproses SATU item outbox: upload data & file terkait ke server,
  /// lalu update status. Dipanggil oleh BackgroundSyncService secara
  /// berurutan untuk tiap item `pendingUpload`/`waitingForInternet`.
  Future<Either<Failure, SyncRecordEntity>> processRecord(String recordId);

  /// Retry manual dari Sync Center - mereset attemptCount agar item
  /// yang sudah exceeds retry limit bisa dicoba lagi atas permintaan
  /// eksplisit user.
  Future<Either<Failure, void>> retryRecord(String recordId);
}
