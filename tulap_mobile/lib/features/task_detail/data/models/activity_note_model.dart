import '../../domain/entities/activity_note_entity.dart';

/// ActivityNoteModel
/// ----------------------------------------------------------------------
/// Model data untuk tabel SQLite `activity_notes`.
/// ----------------------------------------------------------------------
class ActivityNoteModel extends ActivityNoteEntity {
  const ActivityNoteModel({
    required super.id,
    required super.taskId,
    required super.content,
    required super.createdAt,
    super.updatedAt,
    super.syncStatus,
  });

  factory ActivityNoteModel.fromEntity(ActivityNoteEntity entity) {
    return ActivityNoteModel(
      id: entity.id,
      taskId: entity.taskId,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory ActivityNoteModel.fromMap(Map<String, dynamic> map) {
    return ActivityNoteModel(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      syncStatus: (map['syncStatus'] as String?) ?? 'LOCAL_ONLY',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }
}
