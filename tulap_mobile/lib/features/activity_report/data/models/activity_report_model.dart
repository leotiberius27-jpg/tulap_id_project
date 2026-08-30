import 'dart:convert';
import '../../domain/entities/activity_report_entity.dart';

/// ActivityReportModel
/// ----------------------------------------------------------------------
/// Data model untuk serialisasi database SQLite (activity_reports)
/// dan pertukaran JSON dengan Backend API.
/// ----------------------------------------------------------------------
class ActivityReportModel extends ActivityReportEntity {
  const ActivityReportModel({
    required super.id,
    required super.taskId,
    super.userId,
    required super.reportCode,
    super.reportType = 'ACTIVITY_REPORT',
    super.templateId = 'default_activity',
    super.templateVersion = 1,
    required super.title,
    super.summary,
    super.narrative,
    super.periodStart,
    super.periodEnd,
    super.versionNumber = 1,
    super.status = ReportStatus.generated,
    super.pdfLocalPath,
    super.pdfRemoteUrl,
    required super.contentSnapshotJson,
    required super.reportSha256,
    super.totalExpense = 0.0,
    super.evidenceCount = 0,
    super.receiptCount = 0,
    super.syncStatus = 'LOCAL_ONLY',
    required super.createdAt,
    super.updatedAt,
    super.serverTimestamp,
  });

  factory ActivityReportModel.fromEntity(ActivityReportEntity entity) {
    return ActivityReportModel(
      id: entity.id,
      taskId: entity.taskId,
      userId: entity.userId,
      reportCode: entity.reportCode,
      reportType: entity.reportType,
      templateId: entity.templateId,
      templateVersion: entity.templateVersion,
      title: entity.title,
      summary: entity.summary,
      narrative: entity.narrative,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      versionNumber: entity.versionNumber,
      status: entity.status,
      pdfLocalPath: entity.pdfLocalPath,
      pdfRemoteUrl: entity.pdfRemoteUrl,
      contentSnapshotJson: entity.contentSnapshotJson,
      reportSha256: entity.reportSha256,
      totalExpense: entity.totalExpense,
      evidenceCount: entity.evidenceCount,
      receiptCount: entity.receiptCount,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      serverTimestamp: entity.serverTimestamp,
    );
  }

  factory ActivityReportModel.fromRow(Map<String, dynamic> row) {
    return ActivityReportModel(
      id: row['id'] as String,
      taskId: row['taskId'] as String,
      userId: row['userId'] as String?,
      reportCode: row['reportCode'] as String,
      reportType: (row['reportType'] as String?) ?? 'ACTIVITY_REPORT',
      templateId: (row['templateId'] as String?) ?? 'default_activity',
      templateVersion: (row['templateVersion'] as int?) ?? 1,
      title: row['title'] as String,
      summary: row['summary'] as String?,
      narrative: row['narrative'] as String?,
      periodStart: row['periodStart'] != null
          ? DateTime.tryParse(row['periodStart'] as String)
          : null,
      periodEnd: row['periodEnd'] != null
          ? DateTime.tryParse(row['periodEnd'] as String)
          : null,
      versionNumber: (row['versionNumber'] as int?) ?? 1,
      status: ReportStatus.fromString((row['status'] as String?) ?? 'generated'),
      pdfLocalPath: row['pdfLocalPath'] as String?,
      pdfRemoteUrl: row['pdfRemoteUrl'] as String?,
      contentSnapshotJson: (row['contentSnapshotJson'] as String?) ?? '{}',
      reportSha256: (row['reportSha256'] as String?) ?? '',
      totalExpense: (row['totalExpense'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: (row['evidenceCount'] as int?) ?? 0,
      receiptCount: (row['receiptCount'] as int?) ?? 0,
      syncStatus: (row['syncStatus'] as String?) ?? 'LOCAL_ONLY',
      createdAt: DateTime.parse(row['createdAt'] as String),
      updatedAt: row['updatedAt'] != null
          ? DateTime.tryParse(row['updatedAt'] as String)
          : null,
      serverTimestamp: row['serverTimestamp'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'reportCode': reportCode,
      'reportType': reportType,
      'templateId': templateId,
      'templateVersion': templateVersion,
      'title': title,
      'summary': summary,
      'narrative': narrative,
      'periodStart': periodStart?.toIso8601String(),
      'periodEnd': periodEnd?.toIso8601String(),
      'versionNumber': versionNumber,
      'status': status.name,
      'pdfLocalPath': pdfLocalPath,
      'pdfRemoteUrl': pdfRemoteUrl,
      'contentSnapshotJson': contentSnapshotJson,
      'reportSha256': reportSha256,
      'totalExpense': totalExpense,
      'evidenceCount': evidenceCount,
      'receiptCount': receiptCount,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serverTimestamp': serverTimestamp,
    };
  }

  factory ActivityReportModel.fromJson(Map<String, dynamic> json) {
    return ActivityReportModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String?,
      reportCode: json['reportCode'] as String,
      reportType: (json['reportType'] as String?) ?? 'ACTIVITY_REPORT',
      templateId: (json['templateId'] as String?) ?? 'default_activity',
      templateVersion: (json['templateVersion'] as num?)?.toInt() ?? 1,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      narrative: json['narrative'] as String?,
      periodStart: json['periodStart'] != null
          ? DateTime.tryParse(json['periodStart'] as String)
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.tryParse(json['periodEnd'] as String)
          : null,
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
      status: ReportStatus.fromString((json['status'] as String?) ?? 'generated'),
      pdfLocalPath: json['pdfLocalPath'] as String?,
      pdfRemoteUrl: json['pdfRemoteUrl'] as String?,
      contentSnapshotJson: json['contentSnapshotJson'] is String
          ? json['contentSnapshotJson'] as String
          : jsonEncode(json['contentSnapshotJson'] ?? {}),
      reportSha256: (json['reportSha256'] as String?) ?? '',
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
      syncStatus: (json['syncStatus'] as String?) ?? 'SYNCED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      serverTimestamp: json['serverTimestamp'] as String?,
    );
  }
}
