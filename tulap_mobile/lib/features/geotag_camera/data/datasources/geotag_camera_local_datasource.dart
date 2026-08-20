import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/imaging/watermark_compositor.dart';
import '../../../../core/security/hash_generator.dart';
import '../models/geotag_photo_model.dart';

/// Target ukuran maksimum foto setelah kompresi, sesuai Bagian 31
/// dokumen spesifikasi ("Local Image Compression ~300KB/foto").
const int _kTargetMaxFileSizeBytes = 300 * 1024;

/// GeotagCameraLocalDataSource
/// ----------------------------------------------------------------------
/// Lapisan paling teknis: berbicara langsung dengan hardware kamera
/// (package `camera`), file system, dan database lokal SQLite. Semua
/// exception teknis (izin ditolak, disk penuh, dsb) dilempar apa
/// adanya di sini - penanganan jadi Failure dilakukan di
/// GeotagCameraRepositoryImpl (lapisan di atasnya).
/// ----------------------------------------------------------------------
class GeotagCameraLocalDataSource {
  final HashGenerator _hashGenerator;
  final WatermarkCompositor _watermarkCompositor;
  final Database _database;
  final Uuid _uuid = const Uuid();

  GeotagCameraLocalDataSource({
    required HashGenerator hashGenerator,
    required WatermarkCompositor watermarkCompositor,
    required Database database,
  })  : _hashGenerator = hashGenerator,
        _watermarkCompositor = watermarkCompositor,
        _database = database;

  /// Mengambil satu frame foto dari [controller] kamera yang sedang
  /// aktif, MEMBAKAR watermark permanen ke gambar (lihat
  /// WatermarkCompositor), menghitung hash dari hasil ber-watermark
  /// tersebut (bukan file mentah pra-watermark - foto ber-watermark
  /// INILAH artefak bukti resmi yang sesungguhnya diserahkan untuk
  /// audit), mengompresnya, lalu menyimpan record ke tabel lokal
  /// `geotag_photos`.
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

    // 1. Ambil foto mentah dari kamera
    final XFile rawFile = await controller.takePicture();
    final rawBytes = await File(rawFile.path).readAsBytes();

    // 2. Bakar watermark permanen ke gambar - lihat catatan lama di
    // WatermarkOverlay yang secara eksplisit menunda langkah ini ke
    // "layer data" (di sinilah tempatnya).
    final watermarkedBytes = await _watermarkCompositor.compose(
      sourceImageBytes: rawBytes,
      data: watermarkData,
    );
    final dir = await getApplicationDocumentsDirectory();
    final watermarkedPath =
        '${dir.path}/tulap_watermarked_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(watermarkedPath).writeAsBytes(watermarkedBytes);

    // 3. Hash dihitung dari file BER-WATERMARK (artefak resmi), SEBELUM
    // kompresi (lihat catatan di HashGenerator soal urutan ini).
    final integrityHash = await _hashGenerator.generateSha256(watermarkedPath);

    // 4. Kompresi untuk hemat storage & bandwidth upload - juga yang
    // mengonversi PNG hasil compositing menjadi JPEG akhir.
    final compressedPath = await _compressImage(watermarkedPath);

    final id = _uuid.v4();
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
      caption: caption,
    );

    await _database.insert('geotag_photos', model.toJson());

    // File mentah & file ber-watermark pra-kompresi tidak lagi
    // dibutuhkan setelah hash dihitung dan versi kompresi tersimpan -
    // hapus keduanya untuk hemat ruang.
    for (final path in [rawFile.path, watermarkedPath]) {
      final fileOnDisk = File(path);
      if (await fileOnDisk.exists()) {
        await fileOnDisk.delete();
      }
    }

    return model;
  }

  Future<String> _compressImage(String originalPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath =
        '${dir.path}/tulap_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Kompresi iteratif: turunkan quality bertahap sampai file di
    // bawah target ~300KB, dengan batas minimum quality 40 agar foto
    // tidak terlalu rusak untuk keperluan audit visual.
    int quality = 85;
    XFile? result;

    do {
      result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        quality: quality,
        // Batasi resolusi ke skala maksimum 1080p - plugin ini hanya
        // MENGECILKAN gambar yang lebih besar dari minWidth/minHeight,
        // tidak pernah memperbesar gambar yang sudah lebih kecil.
        minWidth: 1920,
        minHeight: 1080,
        keepExif: false, // EXIF asli tidak diperlukan - lokasi sudah kita catat manual & lebih terpercaya
      );

      if (result == null) break;

      final size = await File(result.path).length();
      if (size <= _kTargetMaxFileSizeBytes || quality <= 40) break;

      quality -= 15;
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
    await _database.delete('geotag_photos', where: 'id = ?', whereArgs: [photoId]);
  }
}
