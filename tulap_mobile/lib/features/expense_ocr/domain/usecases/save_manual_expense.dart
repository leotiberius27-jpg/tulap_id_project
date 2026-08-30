import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_note_entity.dart';
import '../repositories/expense_ocr_repository.dart';

class SaveManualExpense {
  final ExpenseOcrRepository _repository;

  SaveManualExpense(this._repository);

  Future<Either<Failure, ExpenseNoteEntity>> call({
    required String taskId,
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    String? notes,
    String? paymentMethod,
  }) {
    return _repository.saveManualExpense(
      taskId: taskId,
      vendorName: vendorName,
      transactionDate: transactionDate,
      totalAmount: totalAmount,
      category: category,
      notes: notes,
      paymentMethod: paymentMethod,
    );
  }
}
