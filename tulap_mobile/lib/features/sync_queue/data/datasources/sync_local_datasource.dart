import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/sync_record_entity.dart';
import '../models/sync_record_model.dart';

/// SyncLocalDataSource
/// ----------------------------------------------------------------------
/// CRUD murni ke tabel `sync_queue` di SQLite. Tabel ini adalah
/// implementasi konkret dari pola "outbox" - setiap baris merepresentasi
/// satu unit kerja yang harus terkirim ke server.
/// ----------------------------------------------------------------------
class SyncLocalDataSource {
  final Database _database;
  final Uuid _uuid = const Uuid();

  SyncLocalDataSource(this._database);

  Future<SyncRecordModel> insertRecord({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  }) async {
    final model = SyncRecordModel(
      id: _uuid.v4(),
      entityType: entityType,
      entityLocalId: entityLocalId,
      taskId: taskId,
      status: SyncStatus.pendingUpload,
      attemptCount: 0,
      createdAt: DateTime.now(),
    );

    await _database.insert('sync_queue', model.toMap());
    return model;
  }

  Future<List<SyncRecordModel>> getAll() async {
    final rows = await _database.query('sync_queue', orderBy: 'createdAt ASC');
    return rows.map((row) => SyncRecordModel.fromMap(row)).toList();
  }

  Future<SyncRecordModel?> getById(String id) async {
    final rows = await _database.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return SyncRecordModel.fromMap(rows.first);
  }

  Future<void> updateRecord(SyncRecordModel record) async {
    await _database.update(
      'sync_queue',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteRecord(String id) async {
    await _database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteRecordsByEntityLocalId(String entityLocalId) async {
    await _database.delete(
      'sync_queue',
      where: 'entityLocalId = ?',
      whereArgs: [entityLocalId],
    );
  }
}
