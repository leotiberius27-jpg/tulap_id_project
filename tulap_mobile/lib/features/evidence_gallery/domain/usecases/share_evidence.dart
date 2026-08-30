import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/media/media_share_service.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';

/// ShareEvidence
/// ----------------------------------------------------------------------
/// Membagikan berkas bukti final ber-watermark (foto / video) ke aplikasi lain.
/// ----------------------------------------------------------------------
class ShareEvidence {
  final MediaShareService _shareService;

  ShareEvidence(this._shareService);

  Future<Either<Failure, bool>> call({
    required GeotagPhotoEntity evidence,
    String? taskName,
  }) async {
    try {
      final success = await _shareService.shareEvidence(
        evidence: evidence,
        taskName: taskName,
      );
      if (!success) {
        return const Left(
          ValidationFailure('Media tidak tersedia pada perangkat.'),
        );
      }
      return Right(success);
    } catch (_) {
      return const Left(ServerFailure('Bukti gagal dibagikan.'));
    }
  }
}
