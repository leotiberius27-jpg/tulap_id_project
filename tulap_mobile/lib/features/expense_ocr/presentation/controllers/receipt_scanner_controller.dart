import 'package:flutter/foundation.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';
import '../../domain/usecases/save_expense_note.dart';
import '../../domain/usecases/scan_receipt.dart';

enum ReceiptScanStatus { idle, scanning, reviewing, saving, error }

class ReceiptScannerState {
  final ReceiptScanStatus status;
  final ScannedReceiptDraft? draft;
  final String? errorMessage;

  const ReceiptScannerState({
    this.status = ReceiptScanStatus.idle,
    this.draft,
    this.errorMessage,
  });

  ReceiptScannerState copyWith({
    ReceiptScanStatus? status,
    ScannedReceiptDraft? draft,
    String? errorMessage,
  }) {
    return ReceiptScannerState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      errorMessage: errorMessage,
    );
  }
}

/// ReceiptScannerController
/// ----------------------------------------------------------------------
/// Mengorkestrasi alur: Scan -> Review -> Confirm, sesuai Bagian 9
/// spesifikasi. Terpisah jelas antara "hasil OCR mentah" (draft, dari
/// ScanReceipt) dan "nilai final setelah dikoreksi user" (dikirim ke
/// ConfirmAndSaveExpenseNote saat "Simpan Nota" ditekan).
/// ----------------------------------------------------------------------
class ReceiptScannerController extends ChangeNotifier {
  final ScanReceipt _scanReceipt;
  final ConfirmAndSaveExpenseNote _confirmAndSave;
  final String taskId;

  ReceiptScannerState _state = const ReceiptScannerState();
  ReceiptScannerState get state => _state;

  ReceiptScannerController({
    required ScanReceipt scanReceipt,
    required ConfirmAndSaveExpenseNote confirmAndSave,
    required this.taskId,
  })  : _scanReceipt = scanReceipt,
        _confirmAndSave = confirmAndSave;

  void _update(ReceiptScannerState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> captureAndScan() async {
    _update(_state.copyWith(status: ReceiptScanStatus.scanning));

    final result = await _scanReceipt();

    result.fold(
      (failure) => _update(
        ReceiptScannerState(
          status: ReceiptScanStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (draft) => _update(
        ReceiptScannerState(status: ReceiptScanStatus.reviewing, draft: draft),
      ),
    );
  }

  /// Dipanggil dari Review Sheet saat user menekan "Simpan Nota",
  /// dengan nilai yang mungkin sudah dikoreksi lewat "Edit".
  Future<Either2> confirmSave({
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    double? taxAmount,
    String? receiptNumber,
  }) async {
    final draft = _state.draft;
    if (draft == null) {
      return Either2.failure('Data nota tidak ditemukan.');
    }

    _update(_state.copyWith(status: ReceiptScanStatus.saving));

    final result = await _confirmAndSave(
      taskId: taskId,
      draft: draft,
      finalVendorName: vendorName,
      finalTransactionDate: transactionDate,
      finalTotalAmount: totalAmount,
      finalCategory: category,
      finalTaxAmount: taxAmount,
      finalReceiptNumber: receiptNumber,
    );

    return result.fold(
      (failure) {
        _update(_state.copyWith(
          status: ReceiptScanStatus.reviewing,
          errorMessage: failure.message,
        ));
        return Either2.failure(failure.message);
      },
      (note) {
        _update(const ReceiptScannerState(status: ReceiptScanStatus.idle));
        return Either2.success(note);
      },
    );
  }

  void discardAndRescan() {
    _update(const ReceiptScannerState(status: ReceiptScanStatus.idle));
  }
}

/// Helper hasil sederhana untuk dikonsumsi UI tanpa perlu import dartz
/// langsung di widget - menjaga presentation layer tetap ringan.
class Either2 {
  final String? errorMessage;
  final ExpenseNoteEntity? savedNote;

  Either2._({this.errorMessage, this.savedNote});

  factory Either2.success(ExpenseNoteEntity note) => Either2._(savedNote: note);
  factory Either2.failure(String message) => Either2._(errorMessage: message);

  bool get isSuccess => savedNote != null;
}
