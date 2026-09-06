import 'package:flutter/foundation.dart';
import '../../features/sync_queue/domain/entities/sync_record_entity.dart';
import '../../features/sync_queue/domain/usecases/enqueue_sync_item.dart';
import 'security_event_entity.dart';
import 'security_event_local_datasource.dart';

/// ReportSecurityEvent (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil SEGERA setelah GeotagCameraRepositoryImpl memblokir sebuah
/// percobaan capture karena mock location / root device terdeteksi -
/// "secure error callback so the app can notify the admin or database".
/// Menyimpan jejaknya lokal dulu (outbox), lalu mendaftarkannya ke
/// sync_queue yang sama dipakai geotagPhoto/expenseNote, supaya laporan
/// ini tetap terkirim ke `POST /audit-logs/security-event` walau device
/// sedang offline saat pelanggaran terdeteksi.
///
/// SENGAJA tidak pernah melempar exception ke pemanggil - ini adalah
/// pelaporan sekunder (best-effort), kegagalannya TIDAK BOLEH mengganggu
/// alur utama "blokir capture" yang sudah terjadi lebih dulu di
/// repository. Kegagalan hanya di-log lewat debugPrint.
/// ----------------------------------------------------------------------
class ReportSecurityEvent {
  final SecurityEventLocalDataSource _localDataSource;
  final EnqueueSyncItem _enqueueSyncItem;

  ReportSecurityEvent({
    required SecurityEventLocalDataSource localDataSource,
    required EnqueueSyncItem enqueueSyncItem,
  }) : _localDataSource = localDataSource,
       _enqueueSyncItem = enqueueSyncItem;

  Future<void> call({
    required String taskId,
    required SecurityEventType eventType,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    String? deviceInfo,
  }) async {
    try {
      final event = await _localDataSource.insert(
        taskId: taskId,
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        deviceInfo: deviceInfo,
      );

      await _enqueueSyncItem(
        entityType: SyncEntityType.securityEvent,
        entityLocalId: event.id,
        taskId: taskId,
      );
    } catch (e) {
      debugPrint('[SECURITY_EVENT] ⚠️ Gagal mencatat pelanggaran secara lokal: $e');
    }
  }
}
