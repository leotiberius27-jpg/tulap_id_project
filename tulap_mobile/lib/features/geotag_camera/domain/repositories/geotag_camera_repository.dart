import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/geotag_photo_entity.dart';

/// GeotagCameraRepository (interface/kontrak)
/// ----------------------------------------------------------------------
/// Domain layer HANYA mengenal kontrak ini, tidak tahu implementasi
/// konkretnya memakai package `camera`, `geolocator`, atau `sqlite`
/// apa pun - itu urusan `GeotagCameraRepositoryImpl` di layer data.
/// Pola ini memudahkan unit test (bisa di-mock) dan penggantian
/// dependency teknis tanpa menyentuh business logic.
/// ----------------------------------------------------------------------
abstract class GeotagCameraRepository {
  /// Mengambil foto dari kamera perangkat, memvalidasi integritas
  /// lokasi, menghitung hash, lalu menyimpannya secara lokal (belum
  /// diunggah ke server - itu tanggung jawab fitur `sync_queue`).
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSavePhoto({
    required String taskId,
    String? caption,
  });

  /// Menyimpan rekaman video sebagai bukti digital kegiatan lapangan
  /// dengan integritas lokasi pada saat rekaman dimulai, durasi, dan SHA-256.
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSaveVideo({
    required String taskId,
    required String videoPath,
    required Duration duration,
    String? caption,
  });

  /// Mengambil daftar bukti (foto/video) yang sudah tersimpan lokal untuk satu tugas tertentu
  Future<Either<Failure, List<GeotagPhotoEntity>>> getPhotosByTask(
    String taskId,
  );

  /// Menghapus bukti lokal
  Future<Either<Failure, void>> deleteLocalPhoto(String photoId);
}
