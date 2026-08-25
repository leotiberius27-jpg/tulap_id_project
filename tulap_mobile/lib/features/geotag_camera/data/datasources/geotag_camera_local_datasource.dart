import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/imaging/watermark_compositor.dart';
import '../../../../core/security/hash_generator.dart';
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
    required double latitude,
    required double longitude,
    required double gpsAccuracyMeters,
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
    final dir = await getApplicationDocumentsDirectory();

    // 1. Ambil foto mentah dari sensor kamera
    final XFile rawFile = await controller.takePicture();
    final rawBytes = await File(rawFile.path).readAsBytes();

    // 2. Simpan salinan foto asli (Original Photo) untuk preservasi hukum/audit
    final originalPath = '${dir.path}/tulap_raw_${timestampMs}.jpg';
    await File(originalPath).writeAsBytes(rawBytes);

    // 3. Komposisi panel watermark bukti verifikasi permanen
    final watermarkedBytes = await _watermarkCompositor.compose(
      sourceImageBytes: rawBytes,
      data: watermarkData,
    );

    // 4. Tulis file watermark sementara untuk penghitungan hash
    final watermarkedTempPath =
        '${dir.path}/tulap_watermarked_${timestampMs}.png';
    await File(watermarkedTempPath).writeAsBytes(watermarkedBytes);

    // 5. Hitung SHA-256 dari artefak bukti resmi
    final integrityHash = await _hashGenerator.generateSha256(
      watermarkedTempPath,
    );

    // 6. Kompresi salinan ber-watermark menjadi JPEG optimal untuk upload & galeri
    final compressedPath = await _compressImage(watermarkedTempPath);

    // Bersihkan temporary PNG pra-kompresi
    final tempFile = File(watermarkedTempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final model = GeotagPhotoModel(
      id: id,
      taskId: taskId,
      localFilePath: compressedPath,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyMeters: gpsAccuracyMeters,
      plusCode: watermarkData.plusCode,
      serverTimestamp: serverTimestamp,
      integrityHash: integrityHash,
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

  Future<String> _compressImage(String originalPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath =
        '${dir.path}/tulap_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Kompresi berkualitas tinggi (Quality 85) untuk menjaga ketajaman QR Code
    int quality = 85;
    XFile? result;

    do {
      result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
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

  Future<void> deletePhoto(String photoId) async {
    final rows = await _database.query(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [photoId],
    );
    if (rows.isNotEmpty) {
      final path = rows.first['localFilePath'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _database.delete(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }
}
