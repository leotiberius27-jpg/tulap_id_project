import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/geo/plus_code_generator.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../../../core/geo/static_map_fetcher.dart';
import '../../../../core/geo/static_map_thumbnail.dart';
import '../../../../core/imaging/watermark_compositor.dart';
import '../../../../core/security/mock_location_detector.dart';
import '../../../../core/security/report_security_event.dart';
import '../../../../core/security/root_detector.dart';
import '../../../../core/security/security_event_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/entities/watermark_template_entity.dart';
import '../../domain/repositories/geotag_camera_repository.dart';
import '../../domain/repositories/template_repository.dart';
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
  final StaticMapFetcher _staticMapFetcher;
  final TemplateRepository? _templateRepository;
  final ReportSecurityEvent? _reportSecurityEvent;

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
    StaticMapFetcher? staticMapFetcher,
    TemplateRepository? templateRepository,
    ReportSecurityEvent? reportSecurityEvent,
  }) : _localDataSource = localDataSource,
       _mockLocationDetector = mockLocationDetector,
       _rootDetector = rootDetector,
       _cameraController = cameraController,
       _enqueueSyncItem = enqueueSyncItem,
       _getCurrentSession = getCurrentSession,
       _plusCodeGenerator = plusCodeGenerator,
       _reverseGeocoder = reverseGeocoder,
       _staticMapThumbnail = staticMapThumbnail,
       _staticMapFetcher = staticMapFetcher ?? StaticMapFetcher.instance,
       _templateRepository = templateRepository,
       _reportSecurityEvent = reportSecurityEvent;

  /// Melaporkan percobaan capture yang baru saja diblokir - "secure error
  /// callback so the app can notify the admin/database". Best-effort:
  /// tidak pernah dibiarkan melempar exception yang bisa mengganggu
  /// Left(...) yang sudah diputuskan pemanggil di atasnya.
  Future<void> _notifySecurityViolation({
    required String taskId,
    required SecurityEventType eventType,
    required Position? position,
  }) async {
    if (_reportSecurityEvent == null) return;
    try {
      await _reportSecurityEvent(
        taskId: taskId,
        eventType: eventType,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        accuracyMeters: position?.accuracy ?? 0.0,
        deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );
    } catch (_) {
      // Kegagalan pelaporan sekunder TIDAK BOLEH menutupi hasil utama
      // (capture sudah diblokir terlepas dari ini berhasil atau tidak).
    }
  }

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
        await _notifySecurityViolation(
          taskId: taskId,
          eventType: SecurityEventType.rootDeviceBlocked,
          position: FastLocationService.instance.latestCandidatePosition,
        );
        return const Left(DeviceIntegrityFailure());
      }

      final fastLoc = await FastLocationService.instance
          .getAtomicCaptureLocation();
      final eval = fastLoc.position != null
          ? _mockLocationDetector.evaluatePosition(fastLoc.position!)
          : null;
      if (fastLoc.isMocked || (eval?.isMockLocationDetected == true)) {
        // Item 2 (Anti-Fake GPS): blokir instan SUDAH terjadi di atas -
        // baris di bawah ini adalah "secure error callback" yang
        // melaporkan percobaan yang diblokir ke admin/database, tanpa
        // menunda atau mengubah keputusan blokir yang sudah diambil.
        await _notifySecurityViolation(
          taskId: taskId,
          eventType: SecurityEventType.mockLocationBlocked,
          position: fastLoc.position,
        );
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

      // Mulai unduh thumbnail peta nyata SEKARANG (fire-and-forget, TIDAK
      // di-await) - shutter (`controller.takePicture()` di datasource)
      // tidak pernah menunggu jaringan. Hasilnya baru ditunggu (dengan
      // timeout) di dalam WatermarkCompositor.compose(), setelah foto
      // sudah benar-benar dijepret.
      final staticMapFuture = _staticMapFetcher.fetch(latitude: lat, longitude: lng);

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
      final mapsUrl = _staticMapThumbnail.buildGoogleMapsQueryUrl(
        latitude: lat,
        longitude: lng,
      );

      // Konfigurasi template stamp aktif
      final stampConfig = await _templateRepository?.getSavedConfiguration() ??
          const StampConfiguration();

      final model = await _localDataSource.captureAndPersist(
        controller: _cameraController!,
        taskId: taskId,
        userId: currentUser?.id,
        latitude: lat,
        longitude: lng,
        gpsAccuracyMeters: accuracy,
        altitude: fastLoc.altitude,
        heading: fastLoc.heading,
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
          altitude: fastLoc.altitude,
          heading: fastLoc.heading,
          plusCode: plusCode,
          address: address,
          auditQrPayload: mapsUrl,
          staticMapImageBytesFuture: staticMapFuture,
          isOffline: true,
          isVerified: false,
          configuration: stampConfig,
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

  @override
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSaveVideo({
    required String taskId,
    required String videoPath,
    required Duration duration,
    String? caption,
  }) async {
    try {
      final isCompromised = await _rootDetector.isDeviceCompromised();
      if (isCompromised) {
        await _notifySecurityViolation(
          taskId: taskId,
          eventType: SecurityEventType.rootDeviceBlocked,
          position: FastLocationService.instance.latestCandidatePosition,
        );
        return const Left(DeviceIntegrityFailure());
      }

      final fastLoc = await FastLocationService.instance
          .getAtomicCaptureLocation();
      if (fastLoc.isMocked) {
        await _notifySecurityViolation(
          taskId: taskId,
          eventType: SecurityEventType.mockLocationBlocked,
          position: fastLoc.position,
        );
        return const Left(
          LocationInvalidFailure('Mock Location / Fake GPS terdeteksi.'),
        );
      }

      final localTimestamp = DateTime.now();
      final lat = fastLoc.latitude ?? 0.0;
      final lng = fastLoc.longitude ?? 0.0;
      final accuracy = fastLoc.accuracy ?? 10.0;

      final plusCode = _plusCodeGenerator.generate(
        latitude: lat,
        longitude: lng,
      );

      final currentUser = await _getCurrentSession();
      final address = fastLoc.address ?? await _tryReverseGeocode(lat, lng);
      final shortEvidenceId = _generateShortEvidenceId(taskId, localTimestamp);

      final model = await _localDataSource.persistVideoEvidence(
        recordedTempPath: videoPath,
        taskId: taskId,
        userId: currentUser?.id,
        latitude: lat,
        longitude: lng,
        gpsAccuracyMeters: accuracy,
        altitude: fastLoc.altitude,
        heading: fastLoc.heading,
        serverTimestamp: localTimestamp,
        durationSeconds: duration.inSeconds,
        isMockLocationDetected: fastLoc.isMocked,
        isRootedDeviceDetected: isCompromised,
        plusCode: plusCode,
        address: address,
        caption: caption ?? 'Dokumentasi Video Lapangan',
        shortEvidenceId: shortEvidenceId,
      );

      // Daftarkan video ke outbox sync queue
      await _enqueueSyncItem(
        entityType: SyncEntityType.geotagPhoto,
        entityLocalId: model.id,
        taskId: taskId,
      );

      return Right(model);
    } catch (_) {
      return const Left(LocalStorageFailure('Gagal menyimpan rekaman bukti video.'));
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
