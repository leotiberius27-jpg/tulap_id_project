import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../entities/expense_note_entity.dart';
import '../repositories/expense_ocr_repository.dart';

/// ConfirmAndSaveExpenseNote (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil saat user menekan "Simpan Nota" di Review Sheet. Menerima
/// nilai FINAL (bisa berbeda dari hasil OCR mentah jika user melakukan
/// koreksi manual lewat "Edit"), menyimpannya secara lokal, lalu
/// mendaftarkan ke Sync Queue - mengikuti pola yang sama persis dengan
/// CaptureGeotaggedPhoto di fitur geotag_camera.
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
    required double finalTotalAmount,
    required ExpenseCategoryEntity finalCategory,
    double? finalTaxAmount,
    String? finalReceiptNumber,
  }) async {
    final result = await _repository.confirmAndSave(
      taskId: taskId,
      draft: draft,
      finalVendorName: finalVendorName,
      finalTransactionDate: finalTransactionDate,
      finalTotalAmount: finalTotalAmount,
      finalCategory: finalCategory,
      finalTaxAmount: finalTaxAmount,
      finalReceiptNumber: finalReceiptNumber,
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
