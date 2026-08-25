/// ActivityNoteEntity (Catatan Lapangan)
/// ----------------------------------------------------------------------
/// Entitas domain untuk catatan lapangan yang dicatat petugas selama kegiatan.
/// ----------------------------------------------------------------------
class ActivityNoteEntity {
  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  const ActivityNoteEntity({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'LOCAL_ONLY',
  });

  ActivityNoteEntity copyWith({
    String? id,
    String? taskId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return ActivityNoteEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
