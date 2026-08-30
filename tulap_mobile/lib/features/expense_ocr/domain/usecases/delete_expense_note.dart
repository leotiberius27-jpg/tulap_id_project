import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/expense_ocr_repository.dart';

class DeleteExpenseNote {
  final ExpenseOcrRepository _repository;

  DeleteExpenseNote(this._repository);

  Future<Either<Failure, void>> call({
    required String noteId,
    required String taskId,
  }) {
    return _repository.deleteExpenseNote(noteId, taskId);
  }
}
