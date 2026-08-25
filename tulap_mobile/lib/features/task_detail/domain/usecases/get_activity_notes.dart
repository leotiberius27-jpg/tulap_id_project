import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_note_entity.dart';
import '../repositories/activity_note_repository.dart';

class GetActivityNotes {
  final ActivityNoteRepository _repository;

  GetActivityNotes(this._repository);

  Future<Either<Failure, List<ActivityNoteEntity>>> call(String taskId) {
    return _repository.getNotesByTask(taskId);
  }
}
