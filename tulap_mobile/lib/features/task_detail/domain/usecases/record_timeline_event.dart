import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/timeline_event_entity.dart';
import '../repositories/timeline_repository.dart';

class RecordTimelineEvent {
  final TimelineRepository _repository;

  RecordTimelineEvent(this._repository);

  Future<Either<Failure, TimelineEventEntity>> call({
    required String taskId,
    required TimelineEventType eventType,
    required String title,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return _repository.recordEvent(
      taskId: taskId,
      eventType: eventType,
      title: title,
      description: description,
      timestamp: timestamp,
      metadata: metadata,
    );
  }
}
