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
    super.userId,
    super.mediaType = 'PHOTO',
    required super.localFilePath,
    super.originalFilePath,
    required super.latitude,
    required super.longitude,
    required super.gpsAccuracyMeters,
    super.altitude,
    super.heading,
    required super.plusCode,
    required super.serverTimestamp,
    super.deviceTimestamp,
    super.durationSeconds = 0,
    required super.integrityHash,
    super.originalHash,
    super.finalHash,
    super.shortEvidenceId,
    super.verificationStatus = EvidenceVerificationStatus.recorded,
    super.verifiedAt,
    super.syncStatus = 'LOCAL_ONLY',
    required super.isMockLocationDetected,
    required super.isRootedDeviceDetected,
    super.address,
    super.caption,
  });

  factory GeotagPhotoModel.fromJson(Map<String, dynamic> json) {
    return GeotagPhotoModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String?,
      mediaType: json['mediaType'] as String? ?? 'PHOTO',
      localFilePath: json['localFilePath'] as String,
      originalFilePath: json['originalFilePath'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num).toDouble(),
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      plusCode: json['plusCode'] as String? ?? '',
      serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
      deviceTimestamp: json['deviceTimestamp'] != null
          ? DateTime.tryParse(json['deviceTimestamp'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      integrityHash: json['integrityHash'] as String,
      originalHash: json['originalHash'] as String?,
      finalHash: json['finalHash'] as String?,
      shortEvidenceId: json['shortEvidenceId'] as String?,
      verificationStatus: EvidenceVerificationStatus.fromString(
        json['verificationStatus'] as String?,
      ),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL_ONLY',
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
      'userId': userId,
      'mediaType': mediaType,
      'localFilePath': localFilePath,
      'originalFilePath': originalFilePath,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracyMeters': gpsAccuracyMeters,
      'altitude': altitude,
      'heading': heading,
      'plusCode': plusCode,
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'deviceTimestamp': deviceTimestamp?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'integrityHash': integrityHash,
      'originalHash': originalHash,
      'finalHash': finalHash ?? integrityHash,
      'shortEvidenceId': shortEvidenceId ?? displayEvidenceId,
      'verificationStatus': verificationStatus.toDbString(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'isMockLocationDetected': isMockLocationDetected ? 1 : 0,
      'isRootedDeviceDetected': isRootedDeviceDetected ? 1 : 0,
      'address': address,
      'caption': caption,
    };
  }

  /// Payload khusus untuk endpoint `POST /evidence/upload`
  Map<String, dynamic> toUploadPayload() {
    return {
      'taskId': taskId,
      'userId': userId,
      'mediaType': mediaType,
      'evidenceId': shortEvidenceId ?? displayEvidenceId,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracyMeters': gpsAccuracyMeters,
      'altitude': altitude,
      'heading': heading,
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'deviceTimestamp': deviceTimestamp?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'integrityHash': integrityHash,
      'originalHash': originalHash,
      'finalHash': finalHash ?? integrityHash,
      'verificationStatus': verificationStatus.toDbString(),
      'isMockLocationDetected': isMockLocationDetected,
      'isRootedDeviceDetected': isRootedDeviceDetected,
      'address': address,
      'caption': caption,
    };
  }
}

