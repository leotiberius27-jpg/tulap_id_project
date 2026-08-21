import '../../domain/entities/geotag_photo_entity.dart';

/// GeotagPhotoModel
/// ----------------------------------------------------------------------
/// Extends entity domain dan menambahkan kemampuan serialisasi. Model
/// inilah yang benar-benar disimpan/diambil dari database lokal
/// (SQLite/Hive) dan dikirim ke API backend saat sinkronisasi.
/// ----------------------------------------------------------------------
class GeotagPhotoModel extends GeotagPhotoEntity {
  const GeotagPhotoModel({
    required super.id,
    required super.taskId,
    required super.localFilePath,
    required super.latitude,
    required super.longitude,
    required super.gpsAccuracyMeters,
    required super.plusCode,
    required super.serverTimestamp,
    required super.integrityHash,
    required super.isMockLocationDetected,
    required super.isRootedDeviceDetected,
    super.address,
    super.caption,
  });

  factory GeotagPhotoModel.fromJson(Map<String, dynamic> json) {
    return GeotagPhotoModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      localFilePath: json['localFilePath'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num).toDouble(),
      plusCode: json['plusCode'] as String? ?? '',
      serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
      integrityHash: json['integrityHash'] as String,
      // SQLite tidak punya tipe boolean native - kolom ini tersimpan
      // sebagai INTEGER (0/1), jadi sqflite mengembalikannya sebagai
      // Dart int, BUKAN bool. Cast `as bool` langsung akan selalu
      // throw TypeError saat baris ini dibaca dari database (baru
      // aman kalau row berasal dari sumber lain yang memang sudah
      // bool, mis. respons API). Pola sama seperti
      // ChecklistItemModel.fromJson - dicek eksplisit dulu.
      isMockLocationDetected: json['isMockLocationDetected'] is bool
          ? json['isMockLocationDetected'] as bool
          : json['isMockLocationDetected'] == 1,
      isRootedDeviceDetected: json['isRootedDeviceDetected'] is bool
          ? json['isRootedDeviceDetected'] as bool
          : json['isRootedDeviceDetected'] == 1,
      address: json['address'] as String?,
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'localFilePath': localFilePath,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracyMeters': gpsAccuracyMeters,
      'plusCode': plusCode,
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'integrityHash': integrityHash,
      'isMockLocationDetected': isMockLocationDetected,
      'isRootedDeviceDetected': isRootedDeviceDetected,
      'address': address,
      'caption': caption,
    };
  }

  /// Payload khusus untuk endpoint `POST /evidence/photo` - TIDAK
  /// menyertakan `localFilePath` (path lokal tidak relevan untuk
  /// server) dan file gambar dikirim terpisah sebagai multipart.
  Map<String, dynamic> toUploadPayload() {
    return {
      'taskId': taskId,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracyMeters': gpsAccuracyMeters,
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'integrityHash': integrityHash,
      'isMockLocationDetected': isMockLocationDetected,
      'isRootedDeviceDetected': isRootedDeviceDetected,
      'address': address,
      'caption': caption,
    };
  }
}
