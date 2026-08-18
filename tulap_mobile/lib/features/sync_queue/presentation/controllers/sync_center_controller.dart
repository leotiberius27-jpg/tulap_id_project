import 'package:flutter/foundation.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../domain/entities/sync_record_entity.dart';
import '../../domain/repositories/sync_queue_repository.dart';

/// SyncCenterController
/// ----------------------------------------------------------------------
/// Menyediakan data untuk layar Sync Center (Bagian 10 spesifikasi):
/// daftar antrian dikelompokkan per status, dan aksi retry per-item
/// maupun retry global.
/// ----------------------------------------------------------------------
class SyncCenterController extends ChangeNotifier {
  final SyncQueueRepository _repository;
  final BackgroundSyncService _backgroundSyncService;

  List<SyncRecordEntity> _records = [];
  List<SyncRecordEntity> get records => _records;

  bool isLoading = false;
  bool isRetryingAll = false;

  SyncCenterController({
    required SyncQueueRepository repository,
    required BackgroundSyncService backgroundSyncService,
  }) : _repository = repository,
       _backgroundSyncService = backgroundSyncService {
    loadRecords();
  }

  List<SyncRecordEntity> get pendingRecords => _records
      .where(
        (r) =>
            r.status == SyncStatus.pendingUpload ||
            r.status == SyncStatus.waitingForInternet ||
            r.status == SyncStatus.uploading,
      )
      .toList();

  List<SyncRecordEntity> get failedRecords =>
      _records.where((r) => r.status == SyncStatus.failed).toList();

  bool get allSynced => _records.every((r) => r.status == SyncStatus.synced);

  Future<void> loadRecords() async {
    isLoading = true;
    notifyListeners();

    final result = await _repository.getAllRecords();
    result.fold((_) => _records = [], (records) => _records = records);

    isLoading = false;
    notifyListeners();
  }

  Future<void> retryOne(String recordId) async {
    await _repository.retryRecord(recordId);
    await loadRecords();
  }

  Future<void> retryAll() async {
    isRetryingAll = true;
    notifyListeners();

    await _backgroundSyncService.triggerManualSync();
    await loadRecords();

    isRetryingAll = false;
    notifyListeners();
  }
}
