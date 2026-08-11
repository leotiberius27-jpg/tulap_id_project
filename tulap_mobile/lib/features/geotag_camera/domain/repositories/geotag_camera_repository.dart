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
  ///
  /// Mengembalikan `Left(Failure)` jika lokasi tidak valid, kamera
  /// gagal diakses, atau penyimpanan lokal gagal.
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSavePhoto({
    required String taskId,
    String? caption,
  });

  /// Mengambil daftar foto yang sudah tersimpan lokal untuk satu tugas
  /// tertentu (dipakai untuk gallery preview di dalam Kamera & Detail
  /// Tugas).
  Future<Either<Failure, List<GeotagPhotoEntity>>> getPhotosByTask(
    String taskId,
  );

  /// Menghapus foto lokal (dipakai saat user menekan "Ambil Ulang" dan
  /// membatalkan hasil capture sebelumnya).
  Future<Either<Failure, void>> deleteLocalPhoto(String photoId);
}
