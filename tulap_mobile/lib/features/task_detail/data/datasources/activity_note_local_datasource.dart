import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/activity_note_model.dart';

abstract class ActivityNoteLocalDatasource {
  Future<List<ActivityNoteModel>> getNotesByTask(String taskId);
  Future<ActivityNoteModel> insertNote(ActivityNoteModel note);
  Future<void> deleteNote(String noteId);
}

class ActivityNoteLocalDatasourceImpl implements ActivityNoteLocalDatasource {
  Future<Database> get _db async => await LocalDatabase.instance;

  @override
  Future<List<ActivityNoteModel>> getNotesByTask(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'activity_notes',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt DESC',
    );
    return rows.map((r) => ActivityNoteModel.fromMap(r)).toList();
  }

  @override
  Future<ActivityNoteModel> insertNote(ActivityNoteModel note) async {
    final db = await _db;
    await db.insert(
      'activity_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final db = await _db;
    await db.delete('activity_notes', where: 'id = ?', whereArgs: [noteId]);
  }
}
