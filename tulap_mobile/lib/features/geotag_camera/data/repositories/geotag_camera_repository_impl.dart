import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/geo/plus_code_generator.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../../../core/geo/static_map_thumbnail.dart';
import '../../../../core/imaging/watermark_compositor.dart';
import '../../../../core/security/mock_location_detector.dart';
import '../../../../core/security/root_detector.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/repositories/geotag_camera_repository.dart';
import '../datasources/geotag_camera_local_datasource.dart';

/// GeotagCameraRepositoryImpl
/// ----------------------------------------------------------------------
/// Menghubungkan pengambilan kamera, validasi integritas perangkat & lokasi,
/// komposisi Evidence Verification Panel, dan penyimpanan lokal SQLite.
/// ----------------------------------------------------------------------
class GeotagCameraRepositoryImpl implements GeotagCameraRepository {
  final GeotagCameraLocalDataSource _localDataSource;
  final MockLocationDetector _mockLocationDetector;
  final RootDetector _rootDetector;
  CameraController? _cameraController;
  final EnqueueSyncItem _enqueueSyncItem;
  final GetCurrentSession _getCurrentSession;
  final PlusCodeGenerator _plusCodeGenerator;
  final ReverseGeocoder _reverseGeocoder;
  final StaticMapThumbnail _staticMapThumbnail;

  GeotagCameraRepositoryImpl({
    required GeotagCameraLocalDataSource localDataSource,
    required MockLocationDetector mockLocationDetector,
    required RootDetector rootDetector,
    CameraController? cameraController,
    required EnqueueSyncItem enqueueSyncItem,
    required GetCurrentSession getCurrentSession,
    required PlusCodeGenerator plusCodeGenerator,
    required ReverseGeocoder reverseGeocoder,
    required StaticMapThumbnail staticMapThumbnail,
  }) : _localDataSource = localDataSource,
       _mockLocationDetector = mockLocationDetector,
       _rootDetector = rootDetector,
       _cameraController = cameraController,
       _enqueueSyncItem = enqueueSyncItem,
       _getCurrentSession = getCurrentSession,
       _plusCodeGenerator = plusCodeGenerator,
       _reverseGeocoder = reverseGeocoder,
       _staticMapThumbnail = staticMapThumbnail;

  void attachCameraController(CameraController controller) {
    _cameraController = controller;
  }

  void detachCameraController() {
    _cameraController = null;
  }

  @override
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSavePhoto({
    required String taskId,
    String? caption,
  }) async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return const Left(CameraFailure('Sensor kamera belum siap digunakan.'));
      }

      // 1. Validasi integritas perangkat & lokasi secara atomik (0ms GPS restart delay)
      final isCompromised = await _rootDetector.isDeviceCompromised();
      if (isCompromised) {
        return const Left(DeviceIntegrityFailure());
      }

      final fastLoc = await FastLocationService.instance
          .getAtomicCaptureLocation();
      if (fastLoc.isMocked) {
        return const Left(
          LocationInvalidFailure('Mock Location / Fake GPS terdeteksi.'),
        );
      }

      if (fastLoc.latitude == null || fastLoc.longitude == null) {
        return const Left(
          LocationInvalidFailure('Koordinat GPS belum tersedia.'),
        );
      }

      final localTimestamp = DateTime.now();
      final lat = fastLoc.latitude!;
      final lng = fastLoc.longitude!;
      final accuracy = fastLoc.accuracy ?? 10.0;

      final plusCode = _plusCodeGenerator.generate(
        latitude: lat,
        longitude: lng,
      );

      // Identitas petugas aktif dari session
      final currentUser = await _getCurrentSession();

      // Gunakan alamat yang sudah di-reverse geocode secara paralel, atau fallback cepat
      final address = fastLoc.address ?? await _tryReverseGeocode(lat, lng);

      // Buat Short Evidence ID yang rapi & human-readable (mis. TL-20260824-0011)
      final shortEvidenceId = _generateShortEvidenceId(taskId, localTimestamp);
      final verificationUrl =
          'https://verify.tulap.id/e/$shortEvidenceId?t=$taskId';

      final model = await _localDataSource.captureAndPersist(
        controller: _cameraController!,
        taskId: taskId,
        latitude: lat,
        longitude: lng,
        gpsAccuracyMeters: accuracy,
        serverTimestamp: localTimestamp,
        isMockLocationDetected: fastLoc.isMocked,
        isRootedDeviceDetected: isCompromised,
        address: address,
        caption: caption,
        watermarkData: WatermarkData(
          officerName: currentUser?.fullName ?? 'Leonardo',
          nip: currentUser?.nip,
          agencyName: currentUser?.instansiName ?? 'BPKAD Kabupaten Mimika',
          taskId: taskId,
          taskName: caption ?? 'Monitoring Tugas Lapangan',
          shortEvidenceId: shortEvidenceId,
          timestamp: localTimestamp,
          latitude: lat,
          longitude: lng,
          gpsAccuracyMeters: accuracy,
          plusCode: plusCode,
          address: address,
          auditQrPayload: verificationUrl,
          isOffline: true,
          isVerified: false,
        ),
      );

      // Daftarkan ke antrian sinkronisasi outbox
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

  String _generateShortEvidenceId(String taskId, DateTime timestamp) {
    final y = timestamp.year.toString();
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final seq = (timestamp.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'TL-$y$m$d-$seq';
  }

  Future<String?> _tryReverseGeocode(double lat, double lng) async {
    try {
      return await _reverseGeocoder
          .reverseGeocode(latitude: lat, longitude: lng)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
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
