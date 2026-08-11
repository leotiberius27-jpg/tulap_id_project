import '../../domain/entities/sync_record_entity.dart';

class SyncRecordModel extends SyncRecordEntity {
  const SyncRecordModel({
    required super.id,
    required super.entityType,
    required super.entityLocalId,
    required super.taskId,
    required super.status,
    required super.attemptCount,
    required super.createdAt,
    super.lastAttemptAt,
    super.lastErrorMessage,
  });

  factory SyncRecordModel.fromMap(Map<String, dynamic> map) {
    return SyncRecordModel(
      id: map['id'] as String,
      entityType: SyncEntityType.values.firstWhere(
        (e) => e.name == map['entityType'],
      ),
      entityLocalId: map['entityLocalId'] as String,
      taskId: map['taskId'] as String,
      status: SyncStatus.values.firstWhere((s) => s.name == map['status']),
      attemptCount: map['attemptCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
      lastErrorMessage: map['lastErrorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType.name,
      'entityLocalId': entityLocalId,
      'taskId': taskId,
      'status': status.name,
      'attemptCount': attemptCount,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastErrorMessage': lastErrorMessage,
    };
  }

  factory SyncRecordModel.fromEntity(SyncRecordEntity entity) {
    return SyncRecordModel(
      id: entity.id,
      entityType: entity.entityType,
      entityLocalId: entity.entityLocalId,
      taskId: entity.taskId,
      status: entity.status,
      attemptCount: entity.attemptCount,
      createdAt: entity.createdAt,
      lastAttemptAt: entity.lastAttemptAt,
      lastErrorMessage: entity.lastErrorMessage,
    );
  }
}
