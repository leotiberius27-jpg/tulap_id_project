import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_note_entity.dart';
import '../repositories/activity_note_repository.dart';

class AddActivityNote {
  final ActivityNoteRepository _repository;

  AddActivityNote(this._repository);

  Future<Either<Failure, ActivityNoteEntity>> call({
    required String taskId,
    required String content,
  }) {
    return _repository.addNote(taskId: taskId, content: content);
  }
}
