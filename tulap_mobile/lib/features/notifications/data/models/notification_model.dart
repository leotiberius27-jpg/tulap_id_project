import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.type,
    required super.title,
    required super.message,
    super.relatedEntityType,
    super.relatedEntityId,
    super.actionType = NotificationActionType.none,
    super.actionPayload,
    super.priority = NotificationPriority.info,
    super.isRead = false,
    required super.createdAt,
    super.readAt,
  });

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      category: entity.category,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      relatedEntityType: entity.relatedEntityType,
      relatedEntityId: entity.relatedEntityId,
      actionType: entity.actionType,
      actionPayload: entity.actionPayload,
      priority: entity.priority,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'current_user',
      category: NotificationCategory.fromString(map['category'] as String? ?? 'sistem'),
      type: NotificationType.fromString(map['type'] as String? ?? 'systemInfo'),
      title: map['title'] as String,
      message: map['message'] as String? ?? map['body'] as String? ?? '',
      relatedEntityType: map['relatedEntityType'] as String?,
      relatedEntityId: map['relatedEntityId'] as String? ?? map['relatedTaskId'] as String?,
      actionType: NotificationActionType.fromString(map['actionType'] as String? ?? 'none'),
      actionPayload: map['actionPayload'] as String?,
      priority: NotificationPriority.fromString(map['priority'] as String? ?? 'info'),
      isRead: (map['isRead'] is int) ? (map['isRead'] as int) == 1 : (map['isRead'] as bool? ?? false),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      readAt: map['readAt'] != null ? DateTime.tryParse(map['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category.name,
      'type': type.name,
      'title': title,
      'message': message,
      'relatedEntityType': relatedEntityType,
      'relatedEntityId': relatedEntityId,
      'actionType': actionType.name,
      'actionPayload': actionPayload,
      'priority': priority.name,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Graceful handling of server API schema or local JSON
    final rawType = json['type'] as String? ?? 'SYSTEM_INFO';
    NotificationType type;
    NotificationCategory category;
    NotificationActionType actionType = NotificationActionType.none;
    String? relatedEntityType;
    String? relatedEntityId = json['relatedTaskId'] as String? ?? json['relatedEntityId'] as String?;

    switch (rawType.toUpperCase()) {
      case 'TASK_ASSIGNED':
      case 'ACTIVITY_RUNNING':
        type = NotificationType.activityRunning;
        category = NotificationCategory.kegiatan;
        actionType = NotificationActionType.openTask;
        relatedEntityType = 'TASK';
        break;
      case 'REVISION_NEEDED':
      case 'ACTIVITY_INCOMPLETE':
        type = NotificationType.activityIncomplete;
        category = NotificationCategory.kegiatan;
        actionType = NotificationActionType.openTask;
        relatedEntityType = 'TASK';
        break;
      case 'TASK_APPROVED':
      case 'ACTIVITY_COMPLETED':
        type = NotificationType.activityCompleted;
        category = NotificationCategory.kegiatan;
        actionType = NotificationActionType.openTask;
        relatedEntityType = 'TASK';
        break;
      case 'SYNC_PENDING':
        type = NotificationType.syncPending;
        category = NotificationCategory.sinkronisasi;
        actionType = NotificationActionType.openSync;
        relatedEntityType = 'SYNC';
        break;
      case 'SYNC_FAILED':
        type = NotificationType.syncFailed;
        category = NotificationCategory.sinkronisasi;
        actionType = NotificationActionType.openSync;
        relatedEntityType = 'SYNC';
        break;
      case 'SYNC_COMPLETED':
        type = NotificationType.syncCompleted;
        category = NotificationCategory.sinkronisasi;
        actionType = NotificationActionType.openSync;
        relatedEntityType = 'SYNC';
        break;
      case 'RECEIPT_PROCESSED':
        type = NotificationType.receiptProcessed;
        category = NotificationCategory.kegiatan;
        actionType = NotificationActionType.openReceipt;
        relatedEntityType = 'RECEIPT';
        break;
      default:
        type = NotificationType.fromString(rawType);
        category = NotificationCategory.fromString(json['category'] as String? ?? 'sistem');
        actionType = NotificationActionType.fromString(json['actionType'] as String? ?? 'none');
        relatedEntityType = json['relatedEntityType'] as String?;
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'current_user',
      category: category,
      type: type,
      title: json['title'] as String,
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      actionType: actionType,
      actionPayload: json['actionPayload'] as String?,
      priority: NotificationPriority.fromString(json['priority'] as String? ?? 'info'),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
}
