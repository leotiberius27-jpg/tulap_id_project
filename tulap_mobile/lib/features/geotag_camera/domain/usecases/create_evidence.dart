import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/geotag_photo_entity.dart';
import '../repositories/geotag_camera_repository.dart';

/// CreateEvidence (UseCase)
/// ----------------------------------------------------------------------
/// Titik masuk terpadu (Unified Evidence Pipeline) untuk menyimpan bukti
/// digital kegiatan lapangan (baik FOTO maupun VIDEO).
/// ----------------------------------------------------------------------
class CreateEvidence {
  final GeotagCameraRepository _repository;

  CreateEvidence(this._repository);

  /// Menyimpan bukti foto
  Future<Either<Failure, GeotagPhotoEntity>> capturePhoto({
    required String taskId,
    String? caption,
  }) {
    return _repository.captureAndSavePhoto(
      taskId: taskId,
      caption: caption,
    );
  }

  /// Menyimpan bukti rekaman video
  Future<Either<Failure, GeotagPhotoEntity>> saveVideo({
    required String taskId,
    required String videoPath,
    required Duration duration,
    String? caption,
  }) {
    return _repository.captureAndSaveVideo(
      taskId: taskId,
      videoPath: videoPath,
      duration: duration,
      caption: caption,
    );
  }
}
