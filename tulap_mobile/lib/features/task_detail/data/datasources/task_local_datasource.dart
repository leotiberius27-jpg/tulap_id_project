import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';

/// TaskLocalDataSource
/// ----------------------------------------------------------------------
/// Menyimpan cache tugas terakhir yang dibuka & seluruh checklist-nya
/// secara lokal, sesuai prinsip offline-first: "User tetap dapat
/// membuka tugas yang sudah tersinkronisasi... mengisi checklist"
/// meski tanpa internet (Bagian 4 dokumen requirement awal).
///
/// Tabel `tasks` dan `task_checklist_items` didefinisikan di
/// LocalDatabase.onCreate (lib/core/database/local_database.dart).
/// ----------------------------------------------------------------------
class TaskLocalDataSource {
  final Database _database;
  TaskLocalDataSource(this._database);

  Future<void> cacheTask(TaskModel task) async {
    await _database.insert(
      'tasks',
      task.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TaskModel?> getCachedTask(String taskId) async {
    final rows = await _database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
    if (rows.isEmpty) return null;

    final checklistItems = await getChecklistItems(taskId);
    final photoCountResult = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM geotag_photos WHERE taskId = ?',
      [taskId],
    );
    final noteCountResult = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM expense_notes WHERE taskId = ?',
      [taskId],
    );

    return TaskModel.fromCacheMap(
      rows.first,
      checklistItems,
      Sqflite.firstIntValue(photoCountResult) ?? 0,
      Sqflite.firstIntValue(noteCountResult) ?? 0,
    );
  }

  Future<void> cacheChecklistItems(List<ChecklistItemModel> items) async {
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        'task_checklist_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChecklistItemModel>> getChecklistItems(String taskId) async {
    final rows = await _database.query(
      'task_checklist_items',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: '"order" ASC',
    );
    return rows.map((row) => ChecklistItemModel.fromJson(row)).toList();
  }

  Future<void> updateChecklistItemLocal(String itemId, bool isCompleted) async {
    await _database.update(
      'task_checklist_items',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
