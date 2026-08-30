import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';

/// EvidenceVerificationResult
/// ----------------------------------------------------------------------
/// Hasil analisis komprehensif integritas bukti foto digital:
/// - Hasil komparasi SHA-256 file fisik vs record tersimpan
/// - Integritas koordinat GPS dan deteksi Mock Location
/// - Verifikasi keterkaitan Surat Tugas (Activity Binding)
/// - Kepemilikan petugas dan instansi (User Binding)
/// - Sinkronisasi Cloud / Penyimpanan Lokal
/// ----------------------------------------------------------------------
class EvidenceVerificationResult {
  final String photoId;
  final String taskId;
  final String shortEvidenceId;
  final String localFilePath;

  // File Integrity
  final bool isFinalHashValid;
  final String computedFinalHash;
  final String storedFinalHash;

  // Original Raw File Integrity
  final bool? isOriginalHashValid;
  final String? computedOriginalHash;
  final String? storedOriginalHash;

  // Location Integrity
  final bool hasValidLocation;
  final double latitude;
  final double longitude;
  final double gpsAccuracyMeters;
  final String? address;
  final String plusCode;
  final bool isMockLocationDetected;

  // Device & Environment Integrity
  final bool isRootedDeviceDetected;

  // Activity & User Binding
  final bool isActivityBound;
  final String? taskTitle;
  final String? officerName;
  final String? agencyName;

  // Timestamps & Sync
  final DateTime? deviceTimestamp;
  final DateTime serverTimestamp;
  final bool isSynced;

  // Overall Verification State
  final EvidenceVerificationStatus overallStatus;
  final DateTime verifiedAt;

  const EvidenceVerificationResult({
    required this.photoId,
    required this.taskId,
    required this.shortEvidenceId,
    required this.localFilePath,
    required this.isFinalHashValid,
    required this.computedFinalHash,
    required this.storedFinalHash,
    this.isOriginalHashValid,
    this.computedOriginalHash,
    this.storedOriginalHash,
    required this.hasValidLocation,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyMeters,
    this.address,
    required this.plusCode,
    required this.isMockLocationDetected,
    required this.isRootedDeviceDetected,
    required this.isActivityBound,
    this.taskTitle,
    this.officerName,
    this.agencyName,
    this.deviceTimestamp,
    required this.serverTimestamp,
    required this.isSynced,
    required this.overallStatus,
    required this.verifiedAt,
  });

  bool get isFullyVerified =>
      overallStatus == EvidenceVerificationStatus.verified;

  bool get isReviewRequired =>
      overallStatus == EvidenceVerificationStatus.reviewRequired;

  bool get isIntegrityFailed =>
      overallStatus == EvidenceVerificationStatus.integrityFailed;

  String get statusBadgeTitle {
    switch (overallStatus) {
      case EvidenceVerificationStatus.verified:
        return 'BUKTI TERVERIFIKASI';
      case EvidenceVerificationStatus.reviewRequired:
        return 'BUKTI PERLU DITINJAU';
      case EvidenceVerificationStatus.integrityFailed:
        return 'INTEGRITAS BUKTI BERMASALAH';
      case EvidenceVerificationStatus.synced:
        return 'TERSIKRONSASI';
      case EvidenceVerificationStatus.recorded:
        return 'DIREKAM SECARA LOKAL';
    }
  }
}
