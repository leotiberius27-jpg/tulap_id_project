import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../../sync_queue/data/datasources/sync_local_datasource.dart';

/// DeleteEvidence
/// ----------------------------------------------------------------------
/// Menghapus bukti kegiatan secara aman (safe deletion):
/// 1. Membatalkan antrian outbox sync jika masih berstatus pending/gagal.
/// 2. Menghapus file fisik lokal (foto/video final & original).
/// 3. Menghapus record metadata dari tabel `geotag_photos`.
/// ----------------------------------------------------------------------
class DeleteEvidence {
  final GeotagCameraLocalDataSource _cameraLocalDataSource;
  final SyncLocalDataSource _syncLocalDataSource;

  DeleteEvidence({
    required GeotagCameraLocalDataSource cameraLocalDataSource,
    required SyncLocalDataSource syncLocalDataSource,
  })  : _cameraLocalDataSource = cameraLocalDataSource,
        _syncLocalDataSource = syncLocalDataSource;

  Future<Either<Failure, void>> call({
    required String evidenceId,
  }) async {
    try {
      // 1. Bersihkan dari antrian outbox sync queue
      await _syncLocalDataSource.deleteRecordsByEntityLocalId(evidenceId);

      // 2. Hapus file fisik dan record metadata dari database
      await _cameraLocalDataSource.deletePhoto(evidenceId);

      return const Right(null);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
