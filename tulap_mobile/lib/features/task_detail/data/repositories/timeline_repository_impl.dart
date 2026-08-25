import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../datasources/timeline_local_datasource.dart';
import '../models/timeline_event_model.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final TimelineLocalDataSource _localDataSource;
  final Uuid _uuid;

  TimelineRepositoryImpl({
    required TimelineLocalDataSource localDataSource,
    Uuid? uuid,
  }) : _localDataSource = localDataSource,
       _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, TimelineEventEntity>> recordEvent({
    required String taskId,
    required TimelineEventType eventType,
    required String title,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = timestamp ?? DateTime.now();
      final event = TimelineEventModel(
        id: _uuid.v4(),
        taskId: taskId,
        eventType: eventType,
        title: title,
        description: description,
        eventTimestamp: now,
        metadata: metadata,
        syncStatus: 'LOCAL_ONLY',
      );

      final saved = await _localDataSource.saveEvent(event);
      return Right(saved);
    } catch (e) {
      return Left(DatabaseFailure('Gagal merekam linimasa: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TimelineEventEntity>>> getTimelineEvents(
    String taskId,
  ) async {
    try {
      final events = await _localDataSource.getEventsByTask(taskId);
      return Right(events);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat linimasa: $e'));
    }
  }
}
