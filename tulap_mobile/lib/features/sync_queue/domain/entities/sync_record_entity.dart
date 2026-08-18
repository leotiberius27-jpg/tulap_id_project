/// SyncEntityType
/// ----------------------------------------------------------------------
/// Jenis data yang bisa masuk antrian sinkronisasi. Setiap fitur yang
/// menghasilkan data offline (kamera, OCR nota, checklist) mendaftarkan
/// entri outbox dengan tipe ini, tanpa SyncQueue perlu tahu detail
/// internal masing-masing fitur.
/// ----------------------------------------------------------------------
enum SyncEntityType { geotagPhoto, expenseNote, taskChecklist }

/// SyncStatus
/// ----------------------------------------------------------------------
/// Selaras dengan wording produk di Bagian 10 & 25 spesifikasi:
/// Tersimpan -> Menunggu Internet -> Mengirim -> Terkirim -> Gagal
/// ----------------------------------------------------------------------
enum SyncStatus { pendingUpload, waitingForInternet, uploading, synced, failed }

/// SyncRecordEntity
/// ----------------------------------------------------------------------
/// Satu baris "outbox" - representasi satu unit kerja yang perlu
/// dikirim ke server. Pola outbox ini memastikan TIDAK ADA data yang
/// hilang meski aplikasi ditutup paksa di tengah proses upload; setiap
/// aksi offline dicatat dulu sebagai record sebelum benar-benar
/// dieksekusi ke jaringan.
/// ----------------------------------------------------------------------
class SyncRecordEntity {
  final String id;
  final SyncEntityType entityType;
  final String
  entityLocalId; // ID lokal dari entity terkait (mis. GeotagPhotoEntity.id)
  final String taskId;

  final SyncStatus status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? lastErrorMessage;

  const SyncRecordEntity({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    required this.taskId,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastErrorMessage,
  });

  /// Batas maksimum percobaan otomatis sebelum item ditandai `failed`
  /// dan menunggu retry MANUAL dari user (lihat Bagian 10: Sync Center
  /// harus menyediakan tombol retry).
  static const int maxAutoRetryAttempts = 5;

  bool get hasExceededRetryLimit => attemptCount >= maxAutoRetryAttempts;

  SyncRecordEntity copyWith({
    SyncStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? lastErrorMessage,
  }) {
    return SyncRecordEntity(
      id: id,
      entityType: entityType,
      entityLocalId: entityLocalId,
      taskId: taskId,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastErrorMessage: lastErrorMessage,
    );
  }
}
