import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/expense_ocr_repository.dart';

/// ScanReceipt (UseCase)
/// ----------------------------------------------------------------------
/// Alur: Scan Nota -> Kamera -> Crop/Deteksi -> OCR -> Review (Bagian 9).
/// Usecase ini mencakup langkah kamera hingga OCR - langkah "Review"
/// & "Confirm" ditangani terpisah oleh ConfirmAndSaveExpenseNote agar
/// user punya kesempatan mengedit sebelum data benar-benar tersimpan.
/// ----------------------------------------------------------------------
class ScanReceipt {
  final ExpenseOcrRepository _repository;

  ScanReceipt(this._repository);

  Future<Either<Failure, ScannedReceiptDraft>> call() {
    return _repository.scanReceipt();
  }
}
