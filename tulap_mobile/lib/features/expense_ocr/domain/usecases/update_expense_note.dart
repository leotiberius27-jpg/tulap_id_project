import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_note_entity.dart';
import '../repositories/expense_ocr_repository.dart';

class UpdateExpenseNote {
  final ExpenseOcrRepository _repository;

  UpdateExpenseNote(this._repository);

  Future<Either<Failure, ExpenseNoteEntity>> call(ExpenseNoteEntity note) {
    return _repository.updateExpenseNote(note);
  }
}
