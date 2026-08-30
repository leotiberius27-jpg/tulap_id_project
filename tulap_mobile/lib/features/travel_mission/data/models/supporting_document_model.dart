import '../../domain/entities/supporting_document_entity.dart';

class SupportingDocumentModel extends SupportingDocumentEntity {
  const SupportingDocumentModel({
    required super.id,
    required super.travelMissionId,
    super.activityId,
    required super.documentType,
    required super.title,
    required super.filePath,
    super.remoteUrl,
    required super.sha256,
    super.syncStatus,
    required super.createdAt,
    super.updatedAt,
  });

  factory SupportingDocumentModel.fromEntity(SupportingDocumentEntity entity) {
    return SupportingDocumentModel(
      id: entity.id,
      travelMissionId: entity.travelMissionId,
      activityId: entity.activityId,
      documentType: entity.documentType,
      title: entity.title,
      filePath: entity.filePath,
      remoteUrl: entity.remoteUrl,
      sha256: entity.sha256,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory SupportingDocumentModel.fromJson(Map<String, dynamic> json) {
    return SupportingDocumentModel(
      id: json['id'] as String,
      travelMissionId: (json['travelMissionId'] ?? json['travel_mission_id']) as String,
      activityId: (json['activityId'] ?? json['activity_id']) as String?,
      documentType: SupportingDocumentType.fromString(
        (json['documentType'] ?? json['document_type']) as String?,
      ),
      title: json['title'] as String? ?? 'Dokumen Pendukung',
      filePath: (json['filePath'] ?? json['localFilePath'] ?? '') as String,
      remoteUrl: (json['remoteUrl'] ?? json['documentUrl'] ?? json['document_url']) as String?,
      sha256: json['sha256'] as String? ?? '',
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
      'activityId': activityId,
      'documentType': documentType.name,
      'title': title,
      'filePath': filePath,
      'remoteUrl': remoteUrl,
      'sha256': sha256,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'id': id,
      'travelMissionId': travelMissionId,
      'activityId': activityId,
      'documentType': documentType.name.toUpperCase(),
      'title': title,
      'sha256': sha256,
    };
  }
}
