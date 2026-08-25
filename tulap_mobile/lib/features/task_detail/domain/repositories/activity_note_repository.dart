import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_note_entity.dart';

abstract class ActivityNoteRepository {
  Future<Either<Failure, List<ActivityNoteEntity>>> getNotesByTask(
    String taskId,
  );
  Future<Either<Failure, ActivityNoteEntity>> addNote({
    required String taskId,
    required String content,
  });
  Future<Either<Failure, void>> deleteNote(String noteId);
}
