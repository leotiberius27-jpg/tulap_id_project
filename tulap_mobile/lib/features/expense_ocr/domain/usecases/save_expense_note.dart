import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../entities/expense_note_entity.dart';
import '../repositories/expense_ocr_repository.dart';

/// ConfirmAndSaveExpenseNote (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil saat user menekan "Simpan Nota" di Review Sheet / Review Page.
/// ----------------------------------------------------------------------
class ConfirmAndSaveExpenseNote {
  final ExpenseOcrRepository _repository;
  final EnqueueSyncItem _enqueueSyncItem;

  ConfirmAndSaveExpenseNote({
    required ExpenseOcrRepository repository,
    required EnqueueSyncItem enqueueSyncItem,
  }) : _repository = repository,
       _enqueueSyncItem = enqueueSyncItem;

  Future<Either<Failure, ExpenseNoteEntity>> call({
    required String taskId,
    required ScannedReceiptDraft draft,
    required String finalVendorName,
    required DateTime finalTransactionDate,
    String? finalTransactionTime,
    required double finalTotalAmount,
    required ExpenseCategoryEntity finalCategory,
    double? finalSubtotal,
    double? finalTaxAmount,
    double? finalDiscountAmount,
    double? finalServiceCharge,
    String? finalReceiptNumber,
    String? finalPaymentMethod,
    String? finalNotes,
  }) async {
    final result = await _repository.confirmAndSave(
      taskId: taskId,
      draft: draft,
      finalVendorName: finalVendorName,
      finalTransactionDate: finalTransactionDate,
      finalTransactionTime: finalTransactionTime,
      finalTotalAmount: finalTotalAmount,
      finalCategory: finalCategory,
      finalSubtotal: finalSubtotal,
      finalTaxAmount: finalTaxAmount,
      finalDiscountAmount: finalDiscountAmount,
      finalServiceCharge: finalServiceCharge,
      finalReceiptNumber: finalReceiptNumber,
      finalPaymentMethod: finalPaymentMethod,
      finalNotes: finalNotes,
    );

    // Daftarkan ke antrian outbox hanya jika penyimpanan lokal berhasil.
    await result.fold(
      (_) async {},
      (note) => _enqueueSyncItem(
        entityType: SyncEntityType.expenseNote,
        entityLocalId: note.id,
        taskId: taskId,
      ),
    );

    return result;
  }
}
