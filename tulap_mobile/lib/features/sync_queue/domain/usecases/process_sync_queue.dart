import '../../../../core/network/network_info.dart';
import '../entities/sync_record_entity.dart';
import '../repositories/sync_queue_repository.dart';

/// ProcessSyncQueueResult
/// ----------------------------------------------------------------------
class ProcessSyncQueueResult {
  final int totalProcessed;
  final int totalSynced;
  final int totalFailed;

  const ProcessSyncQueueResult({
    required this.totalProcessed,
    required this.totalSynced,
    required this.totalFailed,
  });
}

/// ProcessSyncQueue (UseCase)
/// ----------------------------------------------------------------------
/// Memproses seluruh antrian outbox secara BERURUTAN (bukan paralel),
/// sengaja dibuat sekuensial agar:
///   1. Tidak membanjiri backend dengan request bersamaan dari satu
///      perangkat yang baru saja online setelah lama offline.
///   2. Urutan pengiriman data mengikuti urutan pembuatan (FIFO),
///      penting untuk konsistensi data terkait (mis. foto sebelum
///      checklist yang mereferensikannya).
///
/// Item yang sudah melewati `maxAutoRetryAttempts` DILEWATI dari proses
/// otomatis ini - item tsb menunggu retry manual dari user lewat Sync
/// Center, sesuai desain di Bagian 10 spesifikasi.
/// ----------------------------------------------------------------------
class ProcessSyncQueue {
  final SyncQueueRepository _repository;
  final NetworkInfo _networkInfo;

  ProcessSyncQueue({
    required SyncQueueRepository repository,
    required NetworkInfo networkInfo,
  }) : _repository = repository,
       _networkInfo = networkInfo;

  Future<ProcessSyncQueueResult> call() async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      return const ProcessSyncQueueResult(
        totalProcessed: 0,
        totalSynced: 0,
        totalFailed: 0,
      );
    }

    final recordsResult = await _repository.getAllRecords();

    int synced = 0;
    int failed = 0;
    int processed = 0;

    await recordsResult.fold(
      (failure) async {
        // Gagal mengambil daftar antrian - tidak ada yang bisa diproses.
      },
      (records) async {
        final pendingRecords = records.where(
          (r) =>
              (r.status == SyncStatus.pendingUpload ||
                  r.status == SyncStatus.waitingForInternet) &&
              !r.hasExceededRetryLimit,
        );

        for (final record in pendingRecords) {
          processed++;
          final result = await _repository.processRecord(record.id);
          result.fold((_) => failed++, (updated) {
            if (updated.status == SyncStatus.synced) {
              synced++;
            } else {
              failed++;
            }
          });
        }
      },
    );

    return ProcessSyncQueueResult(
      totalProcessed: processed,
      totalSynced: synced,
      totalFailed: failed,
    );
  }
}
