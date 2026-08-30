import 'dart:convert';
import '../../domain/entities/lpj_package_entity.dart';

class LpjPackageModel extends LpjPackageEntity {
  const LpjPackageModel({
    required super.id,
    required super.travelMissionId,
    required super.packageCode,
    required super.versionNumber,
    required super.title,
    super.pdfLocalPath,
    super.pdfRemoteUrl,
    required super.packageSha256,
    required super.completenessScore,
    required super.totalActualExpense,
    super.activityCount,
    super.evidenceCount,
    super.receiptCount,
    super.documentCount,
    required super.contentSnapshotJson,
    super.status,
    super.syncStatus,
    required super.createdAt,
    super.updatedAt,
  });

  factory LpjPackageModel.fromEntity(LpjPackageEntity entity) {
    return LpjPackageModel(
      id: entity.id,
      travelMissionId: entity.travelMissionId,
      packageCode: entity.packageCode,
      versionNumber: entity.versionNumber,
      title: entity.title,
      pdfLocalPath: entity.pdfLocalPath,
      pdfRemoteUrl: entity.pdfRemoteUrl,
      packageSha256: entity.packageSha256,
      completenessScore: entity.completenessScore,
      totalActualExpense: entity.totalActualExpense,
      activityCount: entity.activityCount,
      evidenceCount: entity.evidenceCount,
      receiptCount: entity.receiptCount,
      documentCount: entity.documentCount,
      contentSnapshotJson: entity.contentSnapshotJson,
      status: entity.status,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory LpjPackageModel.fromJson(Map<String, dynamic> json) {
    String snapshotJson = '{}';
    if (json['contentSnapshot'] != null) {
      if (json['contentSnapshot'] is Map) {
        snapshotJson = jsonEncode(json['contentSnapshot']);
      } else if (json['contentSnapshot'] is String) {
        snapshotJson = json['contentSnapshot'] as String;
      }
    } else if (json['contentSnapshotJson'] != null) {
      snapshotJson = json['contentSnapshotJson'] as String;
    }

    return LpjPackageModel(
      id: json['id'] as String,
      travelMissionId: (json['travelMissionId'] ?? json['travel_mission_id']) as String,
      packageCode: (json['packageCode'] ?? json['package_code'] ?? 'LPJ-20260828-0000') as String,
      versionNumber: (json['versionNumber'] ?? json['version_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Paket Laporan Pertanggungjawaban (LPJ)',
      pdfLocalPath: (json['pdfLocalPath'] ?? json['pdf_local_path']) as String?,
      pdfRemoteUrl: (json['pdfRemoteUrl'] ?? json['pdf_url']) as String?,
      packageSha256: (json['packageSha256'] ?? json['package_sha256'] ?? '') as String,
      completenessScore: (json['completenessScore'] ?? json['completeness_score'] as num?)?.toDouble() ?? 0.0,
      totalActualExpense: (json['totalActualExpense'] ?? json['total_actual_expense'] as num?)?.toDouble() ?? 0.0,
      activityCount: (json['activityCount'] ?? json['activity_count'] as num?)?.toInt() ?? 0,
      evidenceCount: (json['evidenceCount'] ?? json['evidence_count'] as num?)?.toInt() ?? 0,
      receiptCount: (json['receiptCount'] ?? json['receipt_count'] as num?)?.toInt() ?? 0,
      documentCount: (json['documentCount'] ?? json['document_count'] as num?)?.toInt() ?? 0,
      contentSnapshotJson: snapshotJson,
      status: LpjPackageStatus.fromString(json['status'] as String?),
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL_ONLY',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'travelMissionId': travelMissionId,
      'packageCode': packageCode,
      'versionNumber': versionNumber,
      'title': title,
      'pdfLocalPath': pdfLocalPath,
      'pdfRemoteUrl': pdfRemoteUrl,
      'packageSha256': packageSha256,
      'completenessScore': completenessScore,
      'totalActualExpense': totalActualExpense,
      'activityCount': activityCount,
      'evidenceCount': evidenceCount,
      'receiptCount': receiptCount,
      'documentCount': documentCount,
      'contentSnapshotJson': contentSnapshotJson,
      'status': status.name,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiPayload() {
    Map<String, dynamic> snapshot = {};
    try {
      snapshot = jsonDecode(contentSnapshotJson);
    } catch (_) {}

    return {
      'id': id,
      'travelMissionId': travelMissionId,
      'packageCode': packageCode,
      'versionNumber': versionNumber,
      'title': title,
      'packageSha256': packageSha256,
      'completenessScore': completenessScore,
      'totalActualExpense': totalActualExpense,
      'activityCount': activityCount,
      'evidenceCount': evidenceCount,
      'receiptCount': receiptCount,
      'documentCount': documentCount,
      'contentSnapshot': snapshot,
      'status': status.name.toUpperCase(),
    };
  }
}
