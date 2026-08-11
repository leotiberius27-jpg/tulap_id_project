import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/geotag_photo_entity.dart';
import '../repositories/geotag_camera_repository.dart';

/// CaptureGeotaggedPhoto (UseCase)
/// ----------------------------------------------------------------------
/// Titik masuk utama saat user menekan tombol capture besar di layar
/// kamera. Usecase ini TIDAK melakukan validasi lokasi sendiri - itu
/// sudah ditegakkan oleh `ValidateLocationIntegrity` yang berjalan
/// kontinu di controller. Tombol capture di UI HARUS di-disable saat
/// status lokasi bukan `valid`, sehingga saat method ini dipanggil,
/// asumsinya lokasi sudah tervalidasi.
///
/// Namun sebagai lapis pertahanan kedua (defense in depth), repository
/// implementation TETAP melakukan pengecekan ulang sebelum benar-benar
/// menyimpan foto - lihat GeotagCameraRepositoryImpl.
/// ----------------------------------------------------------------------
class CaptureGeotaggedPhoto {
  final GeotagCameraRepository _repository;

  CaptureGeotaggedPhoto(this._repository);

  Future<Either<Failure, GeotagPhotoEntity>> call({
    required String taskId,
    String? caption,
  }) {
    return _repository.captureAndSavePhoto(taskId: taskId, caption: caption);
  }
}
