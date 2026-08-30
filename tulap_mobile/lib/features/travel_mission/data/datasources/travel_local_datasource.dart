import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../../../expense_ocr/data/models/expense_note_model.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../task_detail/data/models/task_model.dart';
import '../models/lpj_package_model.dart';
import '../models/supporting_document_model.dart';
import '../models/travel_mission_model.dart';

class TravelLocalDatasource {
  TravelLocalDatasource({LocalDatabase? localDatabase});

  Future<Database> get _db async => await LocalDatabase.instance;

  // --- Travel Missions ---

  Future<void> saveTravelMission(TravelMissionModel mission) async {
    final db = await _db;
    await db.insert(
      'travel_missions',
      mission.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TravelMissionModel?> getTravelMissionById(String id) async {
    final db = await _db;
    final results = await db.query(
      'travel_missions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return TravelMissionModel.fromJson(results.first);
  }

  Future<List<TravelMissionModel>> getTravelMissions({
    String? search,
    String? status,
    int? year,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(status.toLowerCase());
    }

    if (search != null && search.trim().isNotEmpty) {
      final pattern = '%${search.trim()}%';
      whereClauses.add(
        '(title LIKE ? OR destination LIKE ? OR displayId LIKE ? OR assignmentLetterNumber LIKE ?)',
      );
      whereArgs.addAll([pattern, pattern, pattern, pattern]);
    }

    if (year != null) {
      whereClauses.add("strftime('%Y', departureDate) = ?");
      whereArgs.add(year.toString());
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'travel_missions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'departureDate DESC',
    );

    return results.map((e) => TravelMissionModel.fromJson(e)).toList();
  }

  Future<void> updateTravelMissionStatus(String id, String status) async {
    final db = await _db;
    await db.update(
      'travel_missions',
      {'status': status, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTravelMission(String id) async {
    final db = await _db;
    await db.delete('travel_missions', where: 'id = ?', whereArgs: [id]);
    await db.delete('supporting_documents', where: 'travelMissionId = ?', whereArgs: [id]);
    await db.delete('lpj_packages', where: 'travelMissionId = ?', whereArgs: [id]);
  }

  // --- Supporting Documents ---

  Future<void> saveSupportingDocument(SupportingDocumentModel doc) async {
    final db = await _db;
    await db.insert(
      'supporting_documents',
      doc.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SupportingDocumentModel>> getSupportingDocuments(String travelMissionId) async {
    final db = await _db;
    final results = await db.query(
      'supporting_documents',
      where: 'travelMissionId = ?',
      whereArgs: [travelMissionId],
      orderBy: 'createdAt ASC',
    );
    return results.map((e) => SupportingDocumentModel.fromJson(e)).toList();
  }

  Future<void> deleteSupportingDocument(String id) async {
    final db = await _db;
    await db.delete('supporting_documents', where: 'id = ?', whereArgs: [id]);
  }

  // --- LPJ Packages ---

  Future<void> saveLpjPackage(LpjPackageModel pkg) async {
    final db = await _db;
    await db.insert(
      'lpj_packages',
      pkg.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LpjPackageModel>> getLpjPackages(String travelMissionId) async {
    final db = await _db;
    final results = await db.query(
      'lpj_packages',
      where: 'travelMissionId = ?',
      whereArgs: [travelMissionId],
      orderBy: 'versionNumber DESC',
    );
    return results.map((e) => LpjPackageModel.fromJson(e)).toList();
  }

  Future<LpjPackageModel?> getLatestLpjPackage(String travelMissionId) async {
    final db = await _db;
    final results = await db.query(
      'lpj_packages',
      where: 'travelMissionId = ?',
      whereArgs: [travelMissionId],
      orderBy: 'versionNumber DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return LpjPackageModel.fromJson(results.first);
  }

  // --- Linked Activities & Evidence & Expenses ---

  Future<List<TaskModel>> getTasksByTravelId(String travelMissionId) async {
    final db = await _db;
    final taskRows = await db.query(
      'tasks',
      where: 'travelId = ?',
      whereArgs: [travelMissionId],
      orderBy: 'startDate ASC',
    );

    final tasks = <TaskModel>[];
    for (final row in taskRows) {
      final taskId = row['id'] as String;
      final checklistRows = await db.query(
        'task_checklist_items',
        where: 'taskId = ?',
        whereArgs: [taskId],
        orderBy: '"order" ASC',
      );
      final checklist = checklistRows.map((c) => ChecklistItemModel.fromJson(c)).toList();

      final photoCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM geotag_photos WHERE taskId = ?',
              [taskId],
            ),
          ) ??
          0;

      final expenseCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM expense_notes WHERE taskId = ?',
              [taskId],
            ),
          ) ??
          0;

      tasks.add(TaskModel.fromCacheMap(row, checklist, photoCount, expenseCount));
    }

    return tasks;
  }

  Future<List<ExpenseNoteModel>> getDirectExpensesByTravelId(String travelMissionId) async {
    final db = await _db;
    final results = await db.query(
      'expense_notes',
      where: "travelId = ? AND (taskId IS NULL OR taskId = '' OR taskId = ?)",
      whereArgs: [travelMissionId, travelMissionId],
      orderBy: 'transactionDate ASC',
    );
    return results.map((e) => ExpenseNoteModel.fromMap(e)).toList();
  }

  Future<List<ExpenseNoteModel>> getAllExpensesForTravel(
    String travelMissionId,
    List<String> taskIds,
  ) async {
    final db = await _db;
    final allTaskIds = [travelMissionId, ...taskIds];
    final placeholders = List.filled(allTaskIds.length, '?').join(',');

    final results = await db.rawQuery(
      '''
      SELECT * FROM expense_notes 
      WHERE travelId = ? OR taskId IN ($placeholders)
      ORDER BY transactionDate ASC
    ''',
      [travelMissionId, ...allTaskIds],
    );

    // Dedup by id
    final seen = <String>{};
    final expenses = <ExpenseNoteModel>[];
    for (final row in results) {
      final model = ExpenseNoteModel.fromMap(row);
      if (seen.add(model.id)) {
        expenses.add(model);
      }
    }
    return expenses;
  }

  Future<List<GeotagPhotoModel>> getAllPhotosForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return [];
    final db = await _db;
    final placeholders = List.filled(taskIds.length, '?').join(',');
    final results = await db.rawQuery(
      'SELECT * FROM geotag_photos WHERE taskId IN ($placeholders) ORDER BY serverTimestamp ASC',
      taskIds,
    );
    return results.map((e) => GeotagPhotoModel.fromJson(e)).toList();
  }
}
