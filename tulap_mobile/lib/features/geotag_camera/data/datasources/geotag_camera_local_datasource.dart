import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/imaging/watermark_compositor.dart';
import '../../../../core/security/hash_generator.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../models/geotag_photo_model.dart';

/// GeotagCameraLocalDataSource
/// ----------------------------------------------------------------------
/// Menangani pipeline pemrosesan dan penyimpanan foto bukti:
/// 1. Menyimpan foto mentah asli (original photo) tanpa modifikasi.
/// 2. Membakar panel verifikasi bukti permanen (Evidence Verification Panel).
/// 3. Menghitung checksum SHA-256 untuk audit anti-tamper.
/// 4. Mengompresi salinan ber-watermark untuk distribusi & penyimpanan hemat.
/// 5. Menyimpan catatan metadata ke SQLite lokal.
/// ----------------------------------------------------------------------
class GeotagCameraLocalDataSource {
  static const _uuid = Uuid();
  static const int _kTargetMaxFileSizeBytes = 350 * 1024; // Target ~350KB

  final HashGenerator _hashGenerator;
  final WatermarkCompositor _watermarkCompositor;
  final Database _database;

  GeotagCameraLocalDataSource({
    required HashGenerator hashGenerator,
    required WatermarkCompositor watermarkCompositor,
    required Database database,
  }) : _hashGenerator = hashGenerator,
       _watermarkCompositor = watermarkCompositor,
       _database = database;

  Future<GeotagPhotoModel> captureAndPersist({
    required CameraController controller,
    required String taskId,
    String? userId,
    required double latitude,
    required double longitude,
    required double gpsAccuracyMeters,
    double? altitude,
    double? heading,
    required DateTime serverTimestamp,
    required bool isMockLocationDetected,
    required bool isRootedDeviceDetected,
    required WatermarkData watermarkData,
    String? address,
    String? caption,
  }) async {
    if (!controller.value.isInitialized) {
      throw CameraException('NOT_INITIALIZED', 'Kamera belum siap digunakan.');
    }

    final id = _uuid.v4();
    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/tulap_evidence/$taskId/photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    // 1. Ambil foto mentah dari sensor kamera
    final XFile rawFile = await controller.takePicture();
    final rawBytes = await File(rawFile.path).readAsBytes();

    // 2. Simpan salinan foto asli (Original Photo) untuk preservasi hukum/audit
    final originalPath = '${photoDir.path}/${id}_raw.jpg';
    await File(originalPath).writeAsBytes(rawBytes);

    // 3. Hitung SHA-256 dari file foto asli mentah via streaming
    final originalHash = await _hashGenerator.generateSha256(originalPath);

    // 4. Komposisi panel watermark bukti bersih
    final watermarkedBytes = await _watermarkCompositor.compose(
      sourceImageBytes: rawBytes,
      data: watermarkData,
    );

    // 5. Tulis file watermark sementara untuk proses kompresi final
    final watermarkedTempPath = '${photoDir.path}/${id}_watermarked_temp.png';
    await File(watermarkedTempPath).writeAsBytes(watermarkedBytes);

    // 6. Kompresi salinan ber-watermark menjadi JPEG optimal untuk penyimpanan & distribusi
    final compressedPath = await _compressImage(
      watermarkedTempPath,
      targetPath: '${photoDir.path}/${id}.jpg',
    );

    // 7. Hitung SHA-256 dari artefak bukti final yang tersimpan/dibagikan
    final finalHash = await _hashGenerator.generateSha256(compressedPath);

    // Bersihkan temporary PNG pra-kompresi
    final tempFile = File(watermarkedTempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final model = GeotagPhotoModel(
      id: id,
      taskId: taskId,
      userId: userId,
      mediaType: 'PHOTO',
      localFilePath: compressedPath,
      originalFilePath: originalPath,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyMeters: gpsAccuracyMeters,
      altitude: altitude,
      heading: heading,
      plusCode: watermarkData.plusCode,
      serverTimestamp: serverTimestamp,
      deviceTimestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      durationSeconds: 0,
      integrityHash: finalHash,
      originalHash: originalHash,
      finalHash: finalHash,
      shortEvidenceId: watermarkData.shortEvidenceId,
      verificationStatus: EvidenceVerificationStatus.recorded,
      syncStatus: 'LOCAL_ONLY',
      isMockLocationDetected: isMockLocationDetected,
      isRootedDeviceDetected: isRootedDeviceDetected,
      address: address,
      caption: caption ?? watermarkData.taskName,
    );

    await _database.insert('geotag_photos', model.toJson());

    // Bersihkan file cache raw kamera bawaan OS
    final rawCacheFile = File(rawFile.path);
    if (await rawCacheFile.exists() && rawCacheFile.path != originalPath) {
      await rawCacheFile.delete();
    }

    return model;
  }

  /// Menyimpan bukti rekaman video (Video Evidence) ke penyimpanan persisten dan database lokal
  Future<GeotagPhotoModel> persistVideoEvidence({
    required String recordedTempPath,
    required String taskId,
    String? userId,
    required double latitude,
    required double longitude,
    required double gpsAccuracyMeters,
    double? altitude,
    double? heading,
    required DateTime serverTimestamp,
    required int durationSeconds,
    required bool isMockLocationDetected,
    required bool isRootedDeviceDetected,
    required String plusCode,
    String? address,
    String? caption,
    required String shortEvidenceId,
  }) async {
    final rawVideoFile = File(recordedTempPath);
    if (!await rawVideoFile.exists() || (await rawVideoFile.length()) == 0) {
      throw const FileSystemException('File video rekaman tidak valid atau kosong.');
    }

    final id = _uuid.v4();
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/tulap_evidence/$taskId/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    // Pindahkan/salin ke direktori bukti persisten
    final persistentVideoPath = '${videoDir.path}/${id}.mp4';
    await rawVideoFile.copy(persistentVideoPath);

    // Hitung SHA-256 via streaming (tanpa memuat seluruh video ke memori RAM)
    final videoHash = await _hashGenerator.generateSha256(persistentVideoPath);

    final model = GeotagPhotoModel(
      id: id,
      taskId: taskId,
      userId: userId,
      mediaType: 'VIDEO',
      localFilePath: persistentVideoPath,
      originalFilePath: persistentVideoPath,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyMeters: gpsAccuracyMeters,
      altitude: altitude,
      heading: heading,
      plusCode: plusCode,
      serverTimestamp: serverTimestamp,
      deviceTimestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      integrityHash: videoHash,
      originalHash: videoHash,
      finalHash: videoHash,
      shortEvidenceId: shortEvidenceId,
      verificationStatus: EvidenceVerificationStatus.recorded,
      syncStatus: 'LOCAL_ONLY',
      isMockLocationDetected: isMockLocationDetected,
      isRootedDeviceDetected: isRootedDeviceDetected,
      address: address,
      caption: caption ?? 'Rekaman Video Lapangan',
    );

    await _database.insert('geotag_photos', model.toJson());

    // Bersihkan temporary cache file bawaan OS
    if (await rawVideoFile.exists() && rawVideoFile.path != persistentVideoPath) {
      try {
        await rawVideoFile.delete();
      } catch (_) {}
    }

    return model;
  }

  Future<String> _compressImage(
    String originalPath, {
    String? targetPath,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final finalTarget = targetPath ??
        '${dir.path}/tulap_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Kompresi berkualitas tinggi (Quality 85)
    int quality = 85;
    XFile? result;

    do {
      result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        finalTarget,
        quality: quality,
        minWidth: 1920,
        minHeight: 1080,
        keepExif: false,
      );

      if (result == null) break;

      final size = await File(result.path).length();
      if (size <= _kTargetMaxFileSizeBytes || quality <= 50) break;

      quality -= 10;
    } while (true);

    return result?.path ?? originalPath;
  }

  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async {
    final rows = await _database.query(
      'geotag_photos',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'serverTimestamp DESC',
    );
    return rows.map((row) => GeotagPhotoModel.fromJson(row)).toList();
  }

  Future<GeotagPhotoModel?> getEvidenceById(String evidenceId) async {
    final rows = await _database.query(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [evidenceId],
    );
    if (rows.isEmpty) return null;
    return GeotagPhotoModel.fromJson(rows.first);
  }

  Future<void> deletePhoto(String photoId) async {
    final rows = await _database.query(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [photoId],
    );
    if (rows.isNotEmpty) {
      final localPath = rows.first['localFilePath'] as String?;
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final origPath = rows.first['originalFilePath'] as String?;
      if (origPath != null && origPath != localPath) {
        final origFile = File(origPath);
        if (await origFile.exists()) {
          await origFile.delete();
        }
      }
    }
    await _database.delete(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }
}
