import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'security_event_entity.dart';

/// SecurityEventLocalDataSource
/// ----------------------------------------------------------------------
/// CRUD murni ke tabel `security_events`. Mengikuti pola yang sama
/// dengan GeotagCameraLocalDataSource/SyncLocalDataSource: satu sumber
/// kebenaran lokal, dibaca kembali oleh SyncRemoteDataSource saat item
/// diproses dari antrian outbox.
/// ----------------------------------------------------------------------
class SecurityEventLocalDataSource {
  final Database _database;
  final Uuid _uuid = const Uuid();

  SecurityEventLocalDataSource(this._database);

  Future<SecurityEventEntity> insert({
    required String taskId,
    required SecurityEventType eventType,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    String? deviceInfo,
  }) async {
    final event = SecurityEventEntity(
      id: _uuid.v4(),
      taskId: taskId,
      eventType: eventType,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      deviceInfo: deviceInfo,
      detectedAt: DateTime.now(),
    );

    await _database.insert('security_events', {
      'id': event.id,
      'taskId': event.taskId,
      'eventType': event.eventType.name,
      'latitude': event.latitude,
      'longitude': event.longitude,
      'accuracyMeters': event.accuracyMeters,
      'deviceInfo': event.deviceInfo,
      'detectedAt': event.detectedAt.toIso8601String(),
      'syncStatus': 'LOCAL_ONLY',
    });

    return event;
  }

  Future<Map<String, dynamic>?> getRawById(String id) async {
    final rows = await _database.query(
      'security_events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> markSynced(String id) async {
    await _database.update(
      'security_events',
      {'syncStatus': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
