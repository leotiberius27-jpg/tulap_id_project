import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/activity_note_entity.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/repositories/activity_note_repository.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../datasources/activity_note_local_datasource.dart';
import '../models/activity_note_model.dart';

class ActivityNoteRepositoryImpl implements ActivityNoteRepository {
  final ActivityNoteLocalDatasource _localDatasource;
  final TimelineRepository? _timelineRepository;

  ActivityNoteRepositoryImpl({
    required ActivityNoteLocalDatasource localDatasource,
    TimelineRepository? timelineRepository,
  }) : _localDatasource = localDatasource,
       _timelineRepository = timelineRepository;

  @override
  Future<Either<Failure, List<ActivityNoteEntity>>> getNotesByTask(
    String taskId,
  ) async {
    try {
      final models = await _localDatasource.getNotesByTask(taskId);
      return Right(models);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat catatan lapangan: $e'));
    }
  }

  @override
  Future<Either<Failure, ActivityNoteEntity>> addNote({
    required String taskId,
    required String content,
  }) async {
    try {
      final note = ActivityNoteModel(
        id: const Uuid().v4(),
        taskId: taskId,
        content: content.trim(),
        createdAt: DateTime.now(),
        syncStatus: 'LOCAL_ONLY',
      );

      final saved = await _localDatasource.insertNote(note);

      // Rekam event otomatis ke timeline kegiatan
      if (_timelineRepository != null) {
        final snippet = content.length > 40
            ? '${content.substring(0, 40)}...'
            : content;
        await _timelineRepository.recordEvent(
          taskId: taskId,
          eventType: TimelineEventType.noteAdded,
          title: 'Catatan Lapangan Ditambahkan',
          description: snippet,
          timestamp: note.createdAt,
        );
      }

      return Right(saved);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan catatan lapangan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String noteId) async {
    try {
      await _localDatasource.deleteNote(noteId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghapus catatan: $e'));
    }
  }
}
