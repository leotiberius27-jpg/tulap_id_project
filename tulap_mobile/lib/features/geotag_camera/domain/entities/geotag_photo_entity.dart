/// Status Verifikasi Bukti Digital Tulap.id
enum EvidenceVerificationStatus {
  recorded,
  synced,
  verified,
  reviewRequired,
  integrityFailed;

  String get labelIndonesian {
    switch (this) {
      case EvidenceVerificationStatus.recorded:
        return 'Direkam';
      case EvidenceVerificationStatus.synced:
        return 'Tersinkronisasi';
      case EvidenceVerificationStatus.verified:
        return 'Terverifikasi';
      case EvidenceVerificationStatus.reviewRequired:
        return 'Perlu Ditinjau';
      case EvidenceVerificationStatus.integrityFailed:
        return 'Integritas Bermasalah';
    }
  }

  static EvidenceVerificationStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SYNCED':
        return EvidenceVerificationStatus.synced;
      case 'VERIFIED':
        return EvidenceVerificationStatus.verified;
      case 'REVIEW_REQUIRED':
      case 'REVIEWREQUIRED':
        return EvidenceVerificationStatus.reviewRequired;
      case 'INTEGRITY_FAILED':
      case 'INTEGRITYFAILED':
        return EvidenceVerificationStatus.integrityFailed;
      case 'RECORDED':
      default:
        return EvidenceVerificationStatus.recorded;
    }
  }

  String toDbString() {
    switch (this) {
      case EvidenceVerificationStatus.recorded:
        return 'RECORDED';
      case EvidenceVerificationStatus.synced:
        return 'SYNCED';
      case EvidenceVerificationStatus.verified:
        return 'VERIFIED';
      case EvidenceVerificationStatus.reviewRequired:
        return 'REVIEW_REQUIRED';
      case EvidenceVerificationStatus.integrityFailed:
        return 'INTEGRITY_FAILED';
    }
  }
}

/// GeotagPhotoEntity / Digital Field Evidence
/// ----------------------------------------------------------------------
/// Representasi murni "bukti kegiatan lapangan" (Foto / Video) di layer domain.
/// Memisahkan informasi visual manusia dan metadata forensik digital lengkap.
/// ----------------------------------------------------------------------
class GeotagPhotoEntity {
  final String id; // UUID lokal (dibuat di mobile sebelum sync ke server)
  final String taskId;
  final String? userId; // ID akun petugas pemilik bukti
  final String mediaType; // 'PHOTO' atau 'VIDEO'
  final String localFilePath; // Path file bukti final di perangkat
  final String? originalFilePath; // Path salinan file mentah pra-watermark/kompresi

  final double latitude;
  final double longitude;
  final String? address; // Hasil reverse-geocoding, bisa null jika offline
  final double gpsAccuracyMeters;
  final double? altitude;
  final double? heading;
  final String plusCode; // Open Location Code

  final DateTime serverTimestamp; // Wajib dari server / timestamp acuan
  final DateTime? deviceTimestamp; // Timestamp lokal perangkat saat pengambilan
  final int durationSeconds; // Durasi rekaman jika media bertipe VIDEO

  final String integrityHash; // SHA-256 utama dari file bukti akhir
  final String? originalHash; // SHA-256 dari file mentah asli
  final String? finalHash; // SHA-256 dari artefak bukti final tersimpan
  final String? shortEvidenceId; // ID Bukti Ringkas (mis. TL-20260826-9760)

  final EvidenceVerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final String syncStatus; // 'LOCAL_ONLY', 'QUEUED', 'SYNCING', 'SYNCED', 'FAILED'

  final bool isMockLocationDetected;
  final bool isRootedDeviceDetected;

  final String? caption;

  const GeotagPhotoEntity({
    required this.id,
    required this.taskId,
    this.userId,
    this.mediaType = 'PHOTO',
    required this.localFilePath,
    this.originalFilePath,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyMeters,
    this.altitude,
    this.heading,
    required this.plusCode,
    required this.serverTimestamp,
    this.deviceTimestamp,
    this.durationSeconds = 0,
    required this.integrityHash,
    this.originalHash,
    this.finalHash,
    this.shortEvidenceId,
    this.verificationStatus = EvidenceVerificationStatus.recorded,
    this.verifiedAt,
    this.syncStatus = 'LOCAL_ONLY',
    required this.isMockLocationDetected,
    required this.isRootedDeviceDetected,
    this.address,
    this.caption,
  });

  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';
  bool get isPhoto => !isVideo;

  /// Sebuah bukti dianggap layak dipakai sebagai bukti resmi jika
  /// TIDAK ada indikasi mock location maupun perangkat compromised.
  bool get isEligibleAsOfficialEvidence =>
      !isMockLocationDetected && !isRootedDeviceDetected;

  /// Effective final hash
  String get effectiveFinalHash => finalHash ?? integrityHash;

  /// Effective short evidence ID
  String get displayEvidenceId {
    if (shortEvidenceId != null && shortEvidenceId!.isNotEmpty) {
      return shortEvidenceId!;
    }
    final y = serverTimestamp.year.toString();
    final m = serverTimestamp.month.toString().padLeft(2, '0');
    final d = serverTimestamp.day.toString().padLeft(2, '0');
    final suffix = id.length >= 4 ? id.substring(0, 4).toUpperCase() : '0001';
    return 'TL-$y$m$d-$suffix';
  }
}

