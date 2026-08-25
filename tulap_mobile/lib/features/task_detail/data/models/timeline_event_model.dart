import 'dart:convert';
import '../../domain/entities/timeline_event_entity.dart';

/// TimelineEventModel
/// ----------------------------------------------------------------------
/// Data Model untuk serialisasi database SQLite (activity_timeline_events)
/// dan pertukaran JSON dengan Backend API.
/// ----------------------------------------------------------------------
class TimelineEventModel extends TimelineEventEntity {
  const TimelineEventModel({
    required super.id,
    required super.taskId,
    required super.eventType,
    required super.title,
    super.description,
    required super.eventTimestamp,
    super.metadata,
    super.syncStatus,
  });

  factory TimelineEventModel.fromEntity(TimelineEventEntity entity) {
    return TimelineEventModel(
      id: entity.id,
      taskId: entity.taskId,
      eventType: entity.eventType,
      title: entity.title,
      description: entity.description,
      eventTimestamp: entity.eventTimestamp,
      metadata: entity.metadata,
      syncStatus: entity.syncStatus,
    );
  }

  factory TimelineEventModel.fromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? meta;
    if (row['metadataJson'] != null &&
        (row['metadataJson'] as String).isNotEmpty) {
      try {
        meta =
            jsonDecode(row['metadataJson'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return TimelineEventModel(
      id: row['id'] as String,
      taskId: row['taskId'] as String,
      eventType: TimelineEventType.fromString(row['eventType'] as String),
      title: row['title'] as String,
      description: row['description'] as String?,
      eventTimestamp: DateTime.parse(row['eventTimestamp'] as String),
      metadata: meta,
      syncStatus: (row['syncStatus'] as String?) ?? 'LOCAL_ONLY',
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'taskId': taskId,
      'eventType': eventType.name,
      'title': title,
      'description': description,
      'eventTimestamp': eventTimestamp.toIso8601String(),
      'metadataJson': metadata != null ? jsonEncode(metadata) : null,
      'syncStatus': syncStatus,
    };
  }

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String,
      taskId: (json['taskId'] ?? json['task_id']) as String,
      eventType: TimelineEventType.fromString(
        (json['eventType'] ?? json['event_type']) as String,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      eventTimestamp: DateTime.parse(
        (json['eventTimestamp'] ?? json['event_timestamp'] ?? json['createdAt'])
            as String,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      syncStatus: (json['syncStatus'] ?? 'SYNCED') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'event_type': eventType.name,
      'title': title,
      'description': description,
      'event_timestamp': eventTimestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
