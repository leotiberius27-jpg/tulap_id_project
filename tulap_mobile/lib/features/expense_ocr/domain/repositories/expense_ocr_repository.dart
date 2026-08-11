import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_note_entity.dart';

/// Hasil scan mentah sebelum dikonfirmasi user - dipisah dari
/// ExpenseNoteEntity karena di tahap ini belum tentu semua field valid
/// dan belum tentu jadi disimpan (user bisa batalkan di Review Sheet).
class ScannedReceiptDraft {
  final String localScanPath;
  final String? vendorName;
  final DateTime? transactionDate;
  final double? totalAmount;
  final double? taxAmount;
  final String? receiptNumber;
  final ExpenseCategoryEntity category;
  final String ocrRawText;
  final double ocrConfidence;

  const ScannedReceiptDraft({
    required this.localScanPath,
    required this.category,
    required this.ocrRawText,
    required this.ocrConfidence,
    this.vendorName,
    this.transactionDate,
    this.totalAmount,
    this.taxAmount,
    this.receiptNumber,
  });
}

/// ExpenseOcrRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class ExpenseOcrRepository {
  /// Memfoto nota lalu menjalankan OCR + parsing, mengembalikan draft
  /// untuk ditinjau user di Review Sheet - BELUM disimpan permanen.
  Future<Either<Failure, ScannedReceiptDraft>> scanReceipt();

  /// Menyimpan hasil yang sudah dikonfirmasi/diedit user sebagai
  /// ExpenseNoteEntity permanen, termasuk pengecekan duplikat.
  Future<Either<Failure, ExpenseNoteEntity>> confirmAndSave({
    required String taskId,
    required ScannedReceiptDraft draft,
    required String finalVendorName,
    required DateTime finalTransactionDate,
    required double finalTotalAmount,
    required ExpenseCategoryEntity finalCategory,
    double? finalTaxAmount,
    String? finalReceiptNumber,
  });

  Future<Either<Failure, List<ExpenseNoteEntity>>> getNotesByTask(
    String taskId,
  );
}
