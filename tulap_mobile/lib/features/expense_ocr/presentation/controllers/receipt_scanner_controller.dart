import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';
import '../../domain/usecases/save_expense_note.dart';
import '../../domain/usecases/scan_receipt.dart';

enum ReceiptScanStatus { idle, scanning, reviewing, saving, error }

class ReceiptScannerState {
  final ReceiptScanStatus status;
  final ScannedReceiptDraft? draft;
  final String? errorMessage;
  final bool isFlashOn;
  final String? duplicateWarning;

  const ReceiptScannerState({
    this.status = ReceiptScanStatus.idle,
    this.draft,
    this.errorMessage,
    this.isFlashOn = false,
    this.duplicateWarning,
  });

  ReceiptScannerState copyWith({
    ReceiptScanStatus? status,
    ScannedReceiptDraft? draft,
    String? errorMessage,
    bool? isFlashOn,
    String? duplicateWarning,
  }) {
    return ReceiptScannerState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      errorMessage: errorMessage,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      duplicateWarning: duplicateWarning,
    );
  }
}

class ReceiptScannerController extends ChangeNotifier {
  final ScanReceipt _scanReceipt;
  final ConfirmAndSaveExpenseNote _confirmAndSave;
  final ExpenseOcrRepository _repository;
  final String taskId;
  final ImagePicker _picker = ImagePicker();

  ReceiptScannerState _state = const ReceiptScannerState();
  ReceiptScannerState get state => _state;

  ReceiptScannerController({
    required ScanReceipt scanReceipt,
    required ConfirmAndSaveExpenseNote confirmAndSave,
    required ExpenseOcrRepository repository,
    required this.taskId,
  }) : _scanReceipt = scanReceipt,
       _confirmAndSave = confirmAndSave,
       _repository = repository;

  void _update(ReceiptScannerState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> toggleFlash(CameraController cameraController) async {
    try {
      final newFlash = !_state.isFlashOn;
      await cameraController.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      _update(_state.copyWith(isFlashOn: newFlash));
    } catch (_) {}
  }

  Future<void> captureAndScan() async {
    _update(_state.copyWith(status: ReceiptScanStatus.scanning, errorMessage: null));

    final result = await _scanReceipt();

    result.fold(
      (failure) => _update(
        ReceiptScannerState(
          status: ReceiptScanStatus.error,
          errorMessage: failure.message,
          isFlashOn: _state.isFlashOn,
        ),
      ),
      (draft) async {
        // Cek apakah ada duplikat berdasarkan hash atau vendor+tanggal+nominal
        String? dupWarning;
        final dupCheck = await _repository.checkDuplicateReceipt(
          sha256Hash: draft.originalSha256,
          vendorName: draft.vendorName,
          transactionDate: draft.transactionDate,
          totalAmount: draft.totalAmount,
        );
        dupCheck.fold((_) {}, (dupId) {
          if (dupId != null) {
            dupWarning = 'Nota dengan karakteristik serupa sudah pernah tersimpan pada kegiatan ini.';
          }
        });

        _update(
          ReceiptScannerState(
            status: ReceiptScanStatus.reviewing,
            draft: draft,
            isFlashOn: _state.isFlashOn,
            duplicateWarning: dupWarning,
          ),
        );
      },
    );
  }

  Future<void> importFromGalleryAndScan() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;

      _update(_state.copyWith(status: ReceiptScanStatus.scanning, errorMessage: null));

      final result = await _repository.scanReceiptFromFile(
        picked.path,
        source: ExpenseSourceEntity.galleryImport,
      );

      result.fold(
        (failure) => _update(
          ReceiptScannerState(
            status: ReceiptScanStatus.error,
            errorMessage: failure.message,
            isFlashOn: _state.isFlashOn,
          ),
        ),
        (draft) async {
          String? dupWarning;
          final dupCheck = await _repository.checkDuplicateReceipt(
            sha256Hash: draft.originalSha256,
            vendorName: draft.vendorName,
            transactionDate: draft.transactionDate,
            totalAmount: draft.totalAmount,
          );
          dupCheck.fold((_) {}, (dupId) {
            if (dupId != null) {
              dupWarning = 'Nota dengan karakteristik serupa sudah pernah tersimpan.';
            }
          });

          _update(
            ReceiptScannerState(
              status: ReceiptScanStatus.reviewing,
              draft: draft,
              isFlashOn: _state.isFlashOn,
              duplicateWarning: dupWarning,
            ),
          );
        },
      );
    } catch (_) {
      _update(
        ReceiptScannerState(
          status: ReceiptScanStatus.error,
          errorMessage: 'Gagal memproses gambar nota dari galeri.',
          isFlashOn: _state.isFlashOn,
        ),
      );
    }
  }

  Future<Either2> confirmSave({
    required String vendorName,
    required DateTime transactionDate,
    String? transactionTime,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? serviceCharge,
    String? receiptNumber,
    String? paymentMethod,
    String? notes,
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
      finalTransactionTime: transactionTime,
      finalTotalAmount: totalAmount,
      finalCategory: category,
      finalSubtotal: subtotal,
      finalTaxAmount: taxAmount,
      finalDiscountAmount: discountAmount,
      finalServiceCharge: serviceCharge,
      finalReceiptNumber: receiptNumber,
      finalPaymentMethod: paymentMethod,
      finalNotes: notes,
    );

    return result.fold(
      (failure) {
        _update(
          _state.copyWith(
            status: ReceiptScanStatus.reviewing,
            errorMessage: failure.message,
          ),
        );
        return Either2.failure(failure.message);
      },
      (note) {
        _update(const ReceiptScannerState(status: ReceiptScanStatus.idle));
        return Either2.success(note);
      },
    );
  }

  void discardAndRescan() {
    _update(ReceiptScannerState(
      status: ReceiptScanStatus.idle,
      isFlashOn: _state.isFlashOn,
    ));
  }
}

class Either2 {
  final String? errorMessage;
  final ExpenseNoteEntity? savedNote;

  Either2._({this.errorMessage, this.savedNote});

  factory Either2.success(ExpenseNoteEntity note) => Either2._(savedNote: note);
  factory Either2.failure(String message) => Either2._(errorMessage: message);

  bool get isSuccess => savedNote != null;
}
