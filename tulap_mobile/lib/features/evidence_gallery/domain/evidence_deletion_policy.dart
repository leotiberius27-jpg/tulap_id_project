import '../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../sync_queue/domain/entities/sync_record_entity.dart';

/// Alasan sebuah bukti BELUM boleh dihapus dari perangkat.
enum EvidenceDeletionBlockReason {
  /// Belum pernah terkirim (antrean menunggu / belum ada antrean).
  notYetSent,

  /// Sedang dikirim saat ini.
  sending,

  /// Pengiriman gagal dan menunggu "Coba Lagi" di Pusat Sinkronisasi.
  sendFailed,

  /// Salinan ber-watermark sudah terkirim, tetapi file ASLI-nya belum
  /// terverifikasi tersimpan di server.
  originalNotOnServer,
}

class EvidenceDeletionDecision {
  final EvidenceDeletionBlockReason? blockReason;

  const EvidenceDeletionDecision.allowed() : blockReason = null;
  const EvidenceDeletionDecision.blocked(EvidenceDeletionBlockReason reason)
    : blockReason = reason;

  bool get isAllowed => blockReason == null;

  String get title => 'Bukti belum dapat dihapus';

  String get message {
    final reason = blockReason;
    if (reason == null) return '';
    final situation = switch (reason) {
      EvidenceDeletionBlockReason.notYetSent =>
        'Bukti ini belum terkirim ke server. Pengiriman berjalan otomatis saat ada internet.',
      EvidenceDeletionBlockReason.sending =>
        'Bukti ini sedang dikirim ke server.',
      EvidenceDeletionBlockReason.sendFailed =>
        'Pengiriman bukti ini gagal. Buka Pusat Sinkronisasi untuk mengirim ulang.',
      EvidenceDeletionBlockReason.originalNotOnServer =>
        'Salinan ber-watermark sudah terkirim ke server, tetapi file aslinya belum.',
    };
    return '$situation\n\n'
        'File asli (tanpa watermark) belum terverifikasi tersimpan di server '
        'dan saat ini hanya ada di perangkat ini. Agar bukti tidak hilang, '
        'bukti ini tidak dapat dihapus.\n\n'
        'Jika bukti ini keliru, sampaikan ke Verifikator saat pemeriksaan.';
  }
}

/// EvidenceDeletionPolicy
/// ----------------------------------------------------------------------
/// Kebijakan konservatif (N-08): file ASLI sebuah bukti TIDAK BOLEH
/// dihapus dari perangkat sebelum ada konfirmasi bahwa file asli itu
/// sudah terunggah, checksum-nya terverifikasi, dan tersimpan aman di
/// server.
///
/// PENTING - status `synced` BUKAN bukti file asli aman:
///  - Foto: yang diunggah sync hanya file ber-watermark (`localFilePath`),
///    file asli (`originalFilePath`) tidak pernah dikirim ke server.
///  - Video: file yang diunggah memang file aslinya, tetapi hasil
///    verifikasi hash dari server (`hashVerified`) tidak disimpan di
///    perangkat.
/// Model data saat ini tidak bisa membedakan status upload file asli
/// dan watermark, sehingga `_isOriginalVerifiedOnServer` SELALU false
/// dan seluruh bukti diperlakukan belum aman. Ubah HANYA setelah ada
/// field yang mencatat upload file asli + verifikasi checksum dari
/// server (roadmap P1-05), bukan berdasarkan `syncStatus`.
/// ----------------------------------------------------------------------
class EvidenceDeletionPolicy {
  const EvidenceDeletionPolicy();

  EvidenceDeletionDecision evaluate({
    required GeotagPhotoEntity evidence,
    required List<SyncRecordEntity> syncRecords,
  }) {
    if (_isOriginalVerifiedOnServer(evidence)) {
      return const EvidenceDeletionDecision.allowed();
    }
    return EvidenceDeletionDecision.blocked(_reasonFor(evidence, syncRecords));
  }

  bool _isOriginalVerifiedOnServer(GeotagPhotoEntity evidence) => false;

  EvidenceDeletionBlockReason _reasonFor(
    GeotagPhotoEntity evidence,
    List<SyncRecordEntity> syncRecords,
  ) {
    final statuses = syncRecords
        .where((r) => r.entityLocalId == evidence.id)
        .map((r) => r.status)
        .toSet();

    if (statuses.contains(SyncStatus.uploading)) {
      return EvidenceDeletionBlockReason.sending;
    }
    if (statuses.contains(SyncStatus.pendingUpload) ||
        statuses.contains(SyncStatus.waitingForInternet)) {
      return EvidenceDeletionBlockReason.notYetSent;
    }
    if (statuses.contains(SyncStatus.failed)) {
      return EvidenceDeletionBlockReason.sendFailed;
    }
    if (statuses.contains(SyncStatus.synced) ||
        evidence.syncStatus.toUpperCase() == 'SYNCED') {
      return EvidenceDeletionBlockReason.originalNotOnServer;
    }
    return EvidenceDeletionBlockReason.notYetSent;
  }
}
