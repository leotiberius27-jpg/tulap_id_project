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

/// Status mapping camelCase (Dart) <-> SCREAMING_SNAKE_CASE (backend
/// enum TaskStatus) - dipusatkan di sini agar tidak tersebar di banyak
/// tempat.
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
  });

  /// Parsing dari response `GET /tasks/:id` backend - backend
  /// mengembalikan relasi `assignee` sebagai object, bukan hanya ID.
  factory TaskModel.fromApiJson(
    Map<String, dynamic> json, {
    List<ChecklistItemModel> checklistItems = const [],
    int geotagPhotoCount = 0,
    int expenseNoteCount = 0,
  }) {
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
      assigneeName:
          (json['assignee'] as Map<String, dynamic>)['fullName'] as String,
      checklistItems: checklistItems,
      geotagPhotoCount: geotagPhotoCount,
      expenseNoteCount: expenseNoteCount,
    );
  }

  /// Untuk cache lokal - hanya field intinya, checklist disimpan
  /// terpisah di tabel task_checklist_items dan digabung ulang saat dibaca.
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
    );
  }
}
