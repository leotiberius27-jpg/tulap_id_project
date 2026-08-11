import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/mock_location_detector.dart';
import '../../../../core/security/root_detector.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/repositories/geotag_camera_repository.dart';
import '../datasources/geotag_camera_local_datasource.dart';

/// GeotagCameraRepositoryImpl
/// ----------------------------------------------------------------------
/// Implementasi konkret kontrak GeotagCameraRepository. Bertindak
/// sebagai "penjaga gerbang" terakhir: SEBELUM foto benar-benar
/// disimpan lewat datasource, repository ini MENGULANG validasi
/// lokasi & integritas perangkat (defense in depth) - bukan hanya
/// mengandalkan pengecekan yang sudah dilakukan controller UI.
///
/// Ini penting karena antara user melihat status "Lokasi Valid" dan
/// menekan tombol capture, bisa saja beberapa detik berlalu dan
/// kondisi berubah (mis. GPS jump, koneksi mock location baru aktif).
/// ----------------------------------------------------------------------
class GeotagCameraRepositoryImpl implements GeotagCameraRepository {
  final GeotagCameraLocalDataSource _localDataSource;
  final MockLocationDetector _mockLocationDetector;
  final RootDetector _rootDetector;
  final CameraController _cameraController;
  final EnqueueSyncItem _enqueueSyncItem;

  GeotagCameraRepositoryImpl({
    required GeotagCameraLocalDataSource localDataSource,
    required MockLocationDetector mockLocationDetector,
    required RootDetector rootDetector,
    required CameraController cameraController,
    required EnqueueSyncItem enqueueSyncItem,
  })  : _localDataSource = localDataSource,
        _mockLocationDetector = mockLocationDetector,
        _rootDetector = rootDetector,
        _cameraController = cameraController,
        _enqueueSyncItem = enqueueSyncItem;

  @override
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSavePhoto({
    required String taskId,
    String? caption,
  }) async {
    try {
      // --- Lapis pertahanan kedua: validasi ulang sesaat sebelum simpan ---
      final locationResult = await _mockLocationDetector.getValidatedPosition();
      final isCompromised = await _rootDetector.isDeviceCompromised();

      if (isCompromised) {
        return const Left(DeviceIntegrityFailure());
      }
      if (!locationResult.isValid) {
        return const Left(LocationInvalidFailure());
      }

      // Timestamp SEHARUSNYA diambil dari server (mis. lewat NTP-sync
      // time atau API time-sync). Untuk simplisitas offline-first,
      // dipakai jam device saat ini sebagai fallback lokal, dan
      // ditandai untuk direkonsiliasi dengan jam server saat sinkronisasi
      // (lihat catatan di fitur sync_queue).
      final localTimestamp = DateTime.now().toUtc();

      final model = await _localDataSource.captureAndPersist(
        controller: _cameraController,
        taskId: taskId,
        latitude: locationResult.position.latitude,
        longitude: locationResult.position.longitude,
        gpsAccuracyMeters: locationResult.accuracyInMeters,
        serverTimestamp: localTimestamp,
        isMockLocationDetected: locationResult.isMockLocationDetected,
        isRootedDeviceDetected: isCompromised,
        caption: caption,
      );

      // Segera daftarkan ke antrian outbox begitu foto tersimpan lokal -
      // ini SATU-SATUNYA jalur foto akan sampai ke server, baik saat
      // online maupun (tertunda) saat kembali online nanti.
      await _enqueueSyncItem(
        entityType: SyncEntityType.geotagPhoto,
        entityLocalId: model.id,
        taskId: taskId,
      );

      return Right(model);
    } on CameraException catch (_) {
      return const Left(CameraFailure());
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, List<GeotagPhotoEntity>>> getPhotosByTask(
    String taskId,
  ) async {
    try {
      final photos = await _localDataSource.getPhotosByTask(taskId);
      return Right(photos);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocalPhoto(String photoId) async {
    try {
      await _localDataSource.deletePhoto(photoId);
      return const Right(null);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
