import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/data/datasources/task_remote_datasource.dart';

/// GetActivityEvidence
/// ----------------------------------------------------------------------
/// Mengambil seluruh bukti (Foto & Video) khusus untuk satu kegiatan tertentu:
/// 1. Prioritas utama membaca cache SQLite lokal (offline-first, cepat).
/// 2. Jika di perangkat baru / cache lokal kosong, melakukan fallback on-demand
///    ke Cloud Storage (GET /tasks/:id/evidence).
/// 3. Menjaga isolasi bukti per kegiatan agar tidak tercampur.
/// ----------------------------------------------------------------------
class GetActivityEvidence {
  final GeotagCameraLocalDataSource _localDataSource;
  final TaskRemoteDataSource? _remoteDataSource;

  GetActivityEvidence(
    this._localDataSource, {
    TaskRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  Future<Either<Failure, List<GeotagPhotoEntity>>> call(String taskId) async {
    try {
      final photos = await _localDataSource.getPhotosByTask(taskId);
      if (photos.isNotEmpty || _remoteDataSource == null) {
        return Right(photos);
      }

      // Fallback ke Cloud Storage jika perangkat baru atau cache belum ada
      try {
        final cloudData = await _remoteDataSource.getTaskEvidence(taskId);
        final cloudPhotos = (cloudData['photos'] as List? ?? []);
        final mapped = cloudPhotos.map((json) {
          final p = json as Map<String, dynamic>;
          final url = p['photoUrl'] as String? ?? '';
          final isVideo = url.endsWith('.mp4') || (p['mediaType'] == 'VIDEO');

          return GeotagPhotoModel(
            id: p['id'] as String,
            taskId: p['taskId'] as String? ?? taskId,
            userId: p['uploaderId'] as String?,
            mediaType: isVideo ? 'VIDEO' : 'PHOTO',
            localFilePath: url,
            latitude: (p['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (p['longitude'] as num?)?.toDouble() ?? 0.0,
            gpsAccuracyMeters:
                (p['gpsAccuracyMeters'] as num?)?.toDouble() ?? 10.0,
            plusCode: p['plusCode'] as String? ?? '',
            serverTimestamp: p['serverTimestamp'] != null
                ? DateTime.parse(p['serverTimestamp'] as String)
                : DateTime.now(),
            integrityHash: p['integrityHash'] as String? ?? '',
            finalHash: p['integrityHash'] as String?,
            verificationStatus: EvidenceVerificationStatus.synced,
            syncStatus: 'SYNCED',
            isMockLocationDetected: p['isMockLocationFlag'] as bool? ?? false,
            isRootedDeviceDetected: p['isRootedDeviceFlag'] as bool? ?? false,
            address: p['address'] as String?,
            caption: p['caption'] as String?,
          );
        }).toList();

        return Right(mapped);
      } catch (_) {
        return Right(photos);
      }
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
