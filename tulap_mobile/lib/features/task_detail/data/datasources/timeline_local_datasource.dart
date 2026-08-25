import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/timeline_event_model.dart';

abstract class TimelineLocalDataSource {
  Future<TimelineEventModel> saveEvent(TimelineEventModel event);
  Future<List<TimelineEventModel>> getEventsByTask(String taskId);
}

class TimelineLocalDataSourceImpl implements TimelineLocalDataSource {
  Future<Database> get _db async => await LocalDatabase.instance;

  TimelineLocalDataSourceImpl();

  @override
  Future<TimelineEventModel> saveEvent(TimelineEventModel event) async {
    final db = await _db;
    await db.insert(
      'activity_timeline_events',
      event.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return event;
  }

  @override
  Future<List<TimelineEventModel>> getEventsByTask(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'activity_timeline_events',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'eventTimestamp ASC',
    );
    return rows.map((r) => TimelineEventModel.fromRow(r)).toList();
  }
}
