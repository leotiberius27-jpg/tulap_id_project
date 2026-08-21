import '../../domain/entities/notification_entity.dart';

NotificationTypeEntity _typeFromApiString(String value) {
  switch (value) {
    case 'TASK_ASSIGNED':
      return NotificationTypeEntity.taskAssigned;
    case 'REVISION_NEEDED':
      return NotificationTypeEntity.revisionNeeded;
    case 'TASK_APPROVED':
      return NotificationTypeEntity.taskApproved;
    case 'TASK_REJECTED':
      return NotificationTypeEntity.taskRejected;
    case 'LPJ_READY':
      return NotificationTypeEntity.lpjReady;
    default:
      return NotificationTypeEntity.unknown;
  }
}

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.relatedTaskId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: _typeFromApiString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      relatedTaskId: json['relatedTaskId'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
