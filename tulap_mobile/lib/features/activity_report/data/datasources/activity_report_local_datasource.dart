import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/activity_report_model.dart';

abstract class ActivityReportLocalDataSource {
  Future<ActivityReportModel> insertReport(ActivityReportModel model);
  Future<List<ActivityReportModel>> getReportsByTaskId(String taskId);
  Future<ActivityReportModel?> getReportById(String reportId);
  Future<int> getNextVersionNumber(String taskId);
  Future<void> updateReport(ActivityReportModel model);
  Future<void> deleteReport(String reportId);
  Future<String> computeFileSha256(String filePath);
}

class ActivityReportLocalDataSourceImpl implements ActivityReportLocalDataSource {
  Future<Database> get _db async => await LocalDatabase.instance;

  @override
  Future<ActivityReportModel> insertReport(ActivityReportModel model) async {
    final db = await _db;
    await db.insert(
      'activity_reports',
      model.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return model;
  }

  @override
  Future<List<ActivityReportModel>> getReportsByTaskId(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'activity_reports',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'versionNumber DESC, createdAt DESC',
    );
    return rows.map((r) => ActivityReportModel.fromRow(r)).toList();
  }

  @override
  Future<ActivityReportModel?> getReportById(String reportId) async {
    final db = await _db;
    final rows = await db.query(
      'activity_reports',
      where: 'id = ?',
      whereArgs: [reportId],
    );
    if (rows.isEmpty) return null;
    return ActivityReportModel.fromRow(rows.first);
  }

  @override
  Future<int> getNextVersionNumber(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'activity_reports',
      columns: ['MAX(versionNumber) as maxVersion'],
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    if (rows.isEmpty || rows.first['maxVersion'] == null) {
      return 1;
    }
    final maxVer = rows.first['maxVersion'] as int? ?? 0;
    return maxVer + 1;
  }

  @override
  Future<void> updateReport(ActivityReportModel model) async {
    final db = await _db;
    await db.update(
      'activity_reports',
      model.toRow(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final db = await _db;
    final report = await getReportById(reportId);
    if (report?.pdfLocalPath != null && report!.pdfLocalPath!.isNotEmpty) {
      final file = File(report.pdfLocalPath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    await db.delete(
      'activity_reports',
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  @override
  Future<String> computeFileSha256(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return '';
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
