import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
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
  final GetCurrentSession _getCurrentSession;
  final PlusCodeGenerator _plusCodeGenerator;
  final ReverseGeocoder _reverseGeocoder;
  final StaticMapThumbnail _staticMapThumbnail;

  GeotagCameraRepositoryImpl({
    required GeotagCameraLocalDataSource localDataSource,
    required MockLocationDetector mockLocationDetector,
    required RootDetector rootDetector,
    required CameraController cameraController,
    required EnqueueSyncItem enqueueSyncItem,
    required GetCurrentSession getCurrentSession,
    required PlusCodeGenerator plusCodeGenerator,
    required ReverseGeocoder reverseGeocoder,
    required StaticMapThumbnail staticMapThumbnail,
  })  : _localDataSource = localDataSource,
        _mockLocationDetector = mockLocationDetector,
        _rootDetector = rootDetector,
        _cameraController = cameraController,
        _enqueueSyncItem = enqueueSyncItem,
        _getCurrentSession = getCurrentSession,
        _plusCodeGenerator = plusCodeGenerator,
        _reverseGeocoder = reverseGeocoder,
        _staticMapThumbnail = staticMapThumbnail;

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
      final lat = locationResult.position.latitude;
      final lng = locationResult.position.longitude;

      final plusCode = _plusCodeGenerator.generate(latitude: lat, longitude: lng);

      // Identitas petugas untuk watermark - dibaca dari sesi lokal
      // tersimpan (bukan dari parameter widget), murni pembacaan lokal
      // secure storage, tidak butuh jaringan (lihat GetCurrentSession).
      final currentUser = await _getCurrentSession();

      // Alamat & thumbnail peta BEST-EFFORT - keduanya butuh jaringan,
      // dan proses capture TIDAK BOLEH gagal hanya karena keduanya
      // tidak berhasil (prinsip offline-first aplikasi ini). Kegagalan
      // di sini menghasilkan null, bukan melempar exception ke atas.
      final address = await _tryReverseGeocode(lat, lng);
      final mapImageBytes = await _tryFetchStaticMap(lat, lng);

      final auditQrPayload = jsonEncode({
        'app': 'tulap.id',
        'taskId': taskId,
        'lat': lat,
        'lng': lng,
        'plusCode': plusCode,
        'capturedAtUtc': localTimestamp.toIso8601String(),
      });

      final model = await _localDataSource.captureAndPersist(
        controller: _cameraController,
        taskId: taskId,
        latitude: lat,
        longitude: lng,
        gpsAccuracyMeters: locationResult.accuracyInMeters,
        serverTimestamp: localTimestamp,
        isMockLocationDetected: locationResult.isMockLocationDetected,
        isRootedDeviceDetected: isCompromised,
        address: address,
        caption: caption,
        watermarkData: WatermarkData(
          officerName: currentUser?.fullName ?? 'Pengguna',
          nip: currentUser?.nip,
          agencyName: currentUser?.instansiName ?? 'Instansi tidak diketahui',
          taskId: taskId,
          timestamp: localTimestamp,
          latitude: lat,
          longitude: lng,
          plusCode: plusCode,
          address: address,
          auditQrPayload: auditQrPayload,
          staticMapImageBytes: mapImageBytes,
        ),
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

  /// Reverse-geocode BEST-EFFORT - timeout pendek & menelan semua
  /// exception (tidak ada koneksi, layanan geocoding gagal, dst) karena
  /// capture bukti TIDAK BOLEH gagal hanya gara-gara ini.
  Future<String?> _tryReverseGeocode(double lat, double lng) async {
    try {
      return await _reverseGeocoder
          .reverseGeocode(latitude: lat, longitude: lng)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  /// Unduh thumbnail peta statis BEST-EFFORT - sama seperti reverse
  /// geocode di atas, kegagalan jaringan tidak boleh menghentikan
  /// capture (Tulap.id offline-first).
  Future<Uint8List?> _tryFetchStaticMap(double lat, double lng) async {
    try {
      final url = _staticMapThumbnail.buildUrl(latitude: lat, longitude: lng);
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = response.data;
      if (data == null) return null;
      return Uint8List.fromList(data);
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
