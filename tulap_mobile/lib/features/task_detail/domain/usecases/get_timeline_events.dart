import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/timeline_event_entity.dart';
import '../repositories/timeline_repository.dart';

class GetTimelineEvents {
  final TimelineRepository _repository;

  GetTimelineEvents(this._repository);

  Future<Either<Failure, List<TimelineEventEntity>>> call(String taskId) {
    return _repository.getTimelineEvents(taskId);
  }
}
