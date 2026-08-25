import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';

class GetTaskExpenses {
  final ExpenseOcrLocalDataSource _localDataSource;

  GetTaskExpenses(this._localDataSource);

  Future<Either<Failure, List<ExpenseNoteEntity>>> call(String taskId) async {
    try {
      final notes = await _localDataSource.getNotesByTask(taskId);
      return Right(notes);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat daftar nota: $e'));
    }
  }
}
