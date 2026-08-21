import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/geotag_camera_local_datasource.dart';
import '../entities/geotag_photo_entity.dart';

/// GetTaskPhotoPreviews
/// ----------------------------------------------------------------------
/// Membaca foto bukti kegiatan yang SUDAH tersimpan lokal untuk satu
/// tugas - dipakai galeri di Detail Tugas. Sengaja bergantung LANGSUNG
/// ke `GeotagCameraLocalDataSource` (bukan lewat `GeotagCameraRepository`)
/// karena repository itu hanya terdaftar di service locator SELAMA sesi
/// kamera aktif (butuh `CameraController`, lihat `registerCameraSession`
/// di injection_container.dart) - Detail Tugas harus bisa menampilkan
/// galeri TANPA membuka kamera. `GeotagCameraLocalDataSource` sendiri
/// murni operasi SQLite, terdaftar permanen sejak awal aplikasi, jadi
/// aman dipakai di sini.
/// ----------------------------------------------------------------------
class GetTaskPhotoPreviews {
  final GeotagCameraLocalDataSource _localDataSource;

  GetTaskPhotoPreviews(this._localDataSource);

  Future<Either<Failure, List<GeotagPhotoEntity>>> call(String taskId) async {
    try {
      final photos = await _localDataSource.getPhotosByTask(taskId);
      return Right(photos);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
