import '../../domain/entities/task_entity.dart';

class ChecklistItemModel extends ChecklistItemEntity {
  const ChecklistItemModel({
    required super.id,
    required super.taskId,
    required super.label,
    required super.order,
    required super.isMandatory,
    required super.isCompleted,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      label: json['label'] as String,
      order: json['order'] as int,
      isMandatory: json['isMandatory'] is bool
          ? json['isMandatory'] as bool
          : json['isMandatory'] == 1,
      isCompleted: json['isCompleted'] is bool
          ? json['isCompleted'] as bool
          : json['isCompleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'label': label,
      'order': order,
      'isMandatory': isMandatory ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
    };
  }

  factory ChecklistItemModel.fromEntity(ChecklistItemEntity e) {
    return ChecklistItemModel(
      id: e.id,
      taskId: e.taskId,
      label: e.label,
      order: e.order,
      isMandatory: e.isMandatory,
      isCompleted: e.isCompleted,
    );
  }
}

TaskStatusEntity taskStatusFromApiString(String value) {
  switch (value) {
    case 'DRAFT':
      return TaskStatusEntity.draft;
    case 'ONGOING':
      return TaskStatusEntity.ongoing;
    case 'PENDING_VERIFICATION':
      return TaskStatusEntity.pendingVerification;
    case 'REVISION_NEEDED':
      return TaskStatusEntity.revisionNeeded;
    case 'VERIFIED':
      return TaskStatusEntity.verified;
    case 'REJECTED':
      return TaskStatusEntity.rejected;
    case 'COMPLETED':
      return TaskStatusEntity.completed;
    default:
      return TaskStatusEntity.draft;
  }
}

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.taskCode,
    required super.taskName,
    required super.destination,
    required super.startDate,
    required super.endDate,
    required super.budgetAmount,
    required super.status,
    required super.assigneeId,
    required super.assigneeName,
    required super.checklistItems,
    required super.geotagPhotoCount,
    required super.expenseNoteCount,
    super.description,
    super.latestRevisionNote,
    super.isSelfCreated,
    super.syncStatus,
    super.syncVersion,
    super.travelId,
    super.startedAt,
    super.completedAt,
    super.createdAt,
    super.updatedAt,
    super.targetLatitude,
    super.targetLongitude,
    super.locationRadiusMeters,
  });

  factory TaskModel.fromApiJson(
    Map<String, dynamic> json, {
    List<ChecklistItemModel> checklistItems = const [],
    int geotagPhotoCount = 0,
    int expenseNoteCount = 0,
  }) {
    final revisionNotes = json['revisionNotes'] as List?;
    final targetLat = json['targetLatitude'] is num
        ? (json['targetLatitude'] as num).toDouble()
        : null;
    final targetLng = json['targetLongitude'] is num
        ? (json['targetLongitude'] as num).toDouble()
        : null;
    final radius = json['locationRadiusMeters'] is num
        ? (json['locationRadiusMeters'] as num).toDouble()
        : 100.0;

    return TaskModel(
      id: json['id'] as String,
      taskCode: json['taskCode'] as String,
      taskName: json['taskName'] as String,
      destination: json['destination'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      budgetAmount: double.parse(json['budgetAmount'].toString()),
      status: taskStatusFromApiString(json['status'] as String),
      assigneeId: (json['assignee'] as Map<String, dynamic>)['id'] as String,
      assigneeName: (json['assignee'] as Map<String, dynamic>)['fullName'] as String,
      checklistItems: checklistItems,
      geotagPhotoCount: geotagPhotoCount,
      expenseNoteCount: expenseNoteCount,
      latestRevisionNote: (revisionNotes != null && revisionNotes.isNotEmpty)
          ? (revisionNotes.first as Map<String, dynamic>)['note'] as String?
          : null,
      isSelfCreated: (json['isSelfCreated'] as bool?) ?? false,
      syncStatus: 'SYNCED',
      syncVersion: (json['syncVersion'] as int?) ?? 1,
      travelId: (json['travelMissionId'] ?? json['travelId'] ?? json['travel_mission_id']) as String?,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      targetLatitude: targetLat,
      targetLongitude: targetLng,
      locationRadiusMeters: radius,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'taskCode': taskCode,
      'taskName': taskName,
      'destination': destination,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budgetAmount': budgetAmount,
      'status': status.name,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'isSelfCreated': isSelfCreated ? 1 : 0,
      'syncStatus': syncStatus,
      'syncVersion': syncVersion,
      'travelId': travelId,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'targetLatitude': targetLatitude,
      'targetLongitude': targetLongitude,
      'locationRadiusMeters': locationRadiusMeters,
    };
  }

  factory TaskModel.fromCacheMap(
    Map<String, dynamic> map,
    List<ChecklistItemModel> checklistItems,
    int geotagPhotoCount,
    int expenseNoteCount,
  ) {
    return TaskModel(
      id: map['id'] as String,
      taskCode: map['taskCode'] as String,
      taskName: map['taskName'] as String,
      destination: map['destination'] as String,
      description: map['description'] as String?,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      budgetAmount: (map['budgetAmount'] as num).toDouble(),
      status: TaskStatusEntity.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatusEntity.draft,
      ),
      assigneeId: map['assigneeId'] as String,
      assigneeName: map['assigneeName'] as String,
      checklistItems: checklistItems,
      geotagPhotoCount: geotagPhotoCount,
      expenseNoteCount: expenseNoteCount,
      isSelfCreated: map['isSelfCreated'] == 1,
      syncStatus: (map['syncStatus'] as String?) ?? 'SYNCED',
      syncVersion: (map['syncVersion'] as int?) ?? 1,
      travelId: map['travelId'] as String?,
      startedAt: map['startedAt'] != null ? DateTime.tryParse(map['startedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
      targetLatitude: map['targetLatitude'] is num
          ? (map['targetLatitude'] as num).toDouble()
          : null,
      targetLongitude: map['targetLongitude'] is num
          ? (map['targetLongitude'] as num).toDouble()
          : null,
      locationRadiusMeters: map['locationRadiusMeters'] is num
          ? (map['locationRadiusMeters'] as num).toDouble()
          : 100.0,
    );
  }
}
