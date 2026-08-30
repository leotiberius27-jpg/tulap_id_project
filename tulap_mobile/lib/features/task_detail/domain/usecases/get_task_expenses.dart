import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../../expense_ocr/data/models/expense_note_model.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../data/datasources/task_remote_datasource.dart';

class GetTaskExpenses {
  final ExpenseOcrLocalDataSource _localDataSource;
  final TaskRemoteDataSource? _remoteDataSource;

  GetTaskExpenses(this._localDataSource, [this._remoteDataSource]);

  Future<Either<Failure, List<ExpenseNoteEntity>>> call(String taskId) async {
    try {
      final localNotes = await _localDataSource.getNotesByTask(taskId);
      if (localNotes.isNotEmpty) {
        return Right(localNotes);
      }

      // Fallback ke cloud jika cache lokal kosong (mis. ganti HP / baru login)
      if (_remoteDataSource != null) {
        try {
          final cloudData = await _remoteDataSource.getTaskEvidence(taskId);
          final rawReceipts = (cloudData['receipts'] ?? cloudData['expenseNotes']) as List?;
          if (rawReceipts != null && rawReceipts.isNotEmpty) {
            final cloudNotes = rawReceipts
                .map((json) => ExpenseNoteModel.fromApiJson(json as Map<String, dynamic>))
                .toList();

            // Cache lokal agar pembacaan berikutnya instan & offline
            for (final note in cloudNotes) {
              await _localDataSource.persist(note);
            }
            return Right(cloudNotes);
          }
        } catch (_) {}
      }

      return Right(localNotes);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat daftar nota: $e'));
    }
  }
}
