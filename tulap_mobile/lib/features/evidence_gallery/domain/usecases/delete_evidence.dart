import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../../sync_queue/data/datasources/sync_local_datasource.dart';
import '../evidence_deletion_policy.dart';

/// Bukti tidak dihapus karena file aslinya belum aman di server - lihat
/// [EvidenceDeletionPolicy]. Bukan error teknis: UI menampilkan
/// [decision] sebagai penjelasan, bukan pesan gagal.
class EvidenceDeletionBlockedFailure extends Failure {
  final EvidenceDeletionDecision decision;

  EvidenceDeletionBlockedFailure(this.decision) : super(decision.message);
}

/// DeleteEvidence
/// ----------------------------------------------------------------------
/// Menghapus bukti kegiatan dari perangkat HANYA jika
/// [EvidenceDeletionPolicy] mengizinkan. SEBELUM perbaikan N-08 use case
/// ini menghapus baris antrean sync (status apa pun, termasuk yang
/// sedang dikirim), file ber-watermark, file ASLI, dan metadata - untuk
/// foto yang sudah terkirim, salinan asli satu-satunya ikut hilang
/// karena file asli tidak pernah diunggah.
///
/// Sekarang:
///  1. Kebijakan dievaluasi lebih dulu. Jika diblokir, TIDAK ADA yang
///     disentuh (file, metadata, maupun antrean sync).
///  2. Jika kelak diizinkan (file asli terverifikasi di server), file &
///     metadata lokal dihapus, tetapi antrean sync TIDAK dihapus/diubah.
/// ----------------------------------------------------------------------
class DeleteEvidence {
  final GeotagCameraLocalDataSource _cameraLocalDataSource;
  final SyncLocalDataSource _syncLocalDataSource;
  final EvidenceDeletionPolicy _policy = const EvidenceDeletionPolicy();

  DeleteEvidence({
    required GeotagCameraLocalDataSource cameraLocalDataSource,
    required SyncLocalDataSource syncLocalDataSource,
  })  : _cameraLocalDataSource = cameraLocalDataSource,
        _syncLocalDataSource = syncLocalDataSource;

  /// Dipakai UI SEBELUM menampilkan konfirmasi hapus - supaya pengguna
  /// langsung mendapat penjelasan, bukan konfirmasi yang lalu gagal.
  /// `null` jika bukti tidak ditemukan.
  Future<EvidenceDeletionDecision?> check({required String evidenceId}) async {
    final evidence = await _cameraLocalDataSource.getEvidenceById(evidenceId);
    if (evidence == null) return null;
    final syncRecords =
        await _syncLocalDataSource.getRecordsByEntityLocalId(evidenceId);
    return _policy.evaluate(evidence: evidence, syncRecords: syncRecords);
  }

  Future<Either<Failure, void>> call({
    required String evidenceId,
  }) async {
    try {
      final decision = await check(evidenceId: evidenceId);
      if (decision == null) {
        return const Left(NotFoundFailure('Bukti tidak ditemukan.'));
      }
      if (!decision.isAllowed) {
        return Left(EvidenceDeletionBlockedFailure(decision));
      }

      await _cameraLocalDataSource.deletePhoto(
        evidenceId,
        originalVerifiedOnServer: true,
      );

      return const Right(null);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
