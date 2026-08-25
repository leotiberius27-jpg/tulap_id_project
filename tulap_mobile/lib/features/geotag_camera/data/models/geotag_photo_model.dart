import '../../domain/entities/geotag_photo_entity.dart';

/// GeotagPhotoModel
/// ----------------------------------------------------------------------
/// Extends entity domain dan menambahkan kemampuan serialisasi. Model
/// inilah yang disimpan di database lokal (SQLite) dan dikirim ke API backend.
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
      'isMockLocationDetected': isMockLocationDetected ? 1 : 0,
      'isRootedDeviceDetected': isRootedDeviceDetected ? 1 : 0,
      'address': address,
      'caption': caption,
    };
  }

  /// Payload khusus untuk endpoint `POST /evidence/photo`
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
