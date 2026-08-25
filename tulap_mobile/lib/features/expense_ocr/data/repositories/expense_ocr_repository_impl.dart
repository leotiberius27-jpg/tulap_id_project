import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/ocr/receipt_parser.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';
import '../datasources/expense_ocr_local_datasource.dart';
import '../models/expense_note_model.dart';

class OcrScanFailure extends Failure {
  const OcrScanFailure([
    super.message = 'Gagal membaca nota. Coba foto ulang.',
  ]);
}

class DuplicateReceiptFailure extends Failure {
  const DuplicateReceiptFailure([
    super.message = 'Nota ini tampaknya sudah pernah digunakan.',
  ]);
}

/// ExpenseOcrRepositoryImpl
/// ----------------------------------------------------------------------
class ExpenseOcrRepositoryImpl implements ExpenseOcrRepository {
  final ExpenseOcrLocalDataSource _localDataSource;
  CameraController? _cameraController;

  ExpenseOcrRepositoryImpl({
    required ExpenseOcrLocalDataSource localDataSource,
    CameraController? cameraController,
  }) : _localDataSource = localDataSource,
       _cameraController = cameraController;

  void attachCameraController(CameraController controller) {
    _cameraController = controller;
  }

  void detachCameraController() {
    _cameraController = null;
  }

  @override
  Future<Either<Failure, ScannedReceiptDraft>> scanReceipt() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return const Left(
          CameraFailure('Sensor kamera nota belum siap digunakan.'),
        );
      }

      final parsed = await _localDataSource.captureAndScan(_cameraController!);
      final compressedPath = _localDataSource.lastCompressedPath;

      if (compressedPath == null) {
        return const Left(OcrScanFailure());
      }

      final overallConfidence = _averageConfidence(parsed);

      final draft = ScannedReceiptDraft(
        localScanPath: compressedPath,
        vendorName: parsed.vendorName.value,
        transactionDate: parsed.transactionDate.value,
        totalAmount: parsed.totalAmount.value,
        taxAmount: parsed.taxAmount.value,
        receiptNumber: parsed.receiptNumber.value,
        category: _mapCategory(parsed.category),
        ocrRawText: parsed.rawText,
        ocrConfidence: overallConfidence,
      );

      return Right(draft);
    } on CameraException catch (_) {
      return const Left(CameraFailure());
    } catch (_) {
      return const Left(OcrScanFailure());
    }
  }

  @override
  Future<Either<Failure, ExpenseNoteEntity>> confirmAndSave({
    required String taskId,
    required ScannedReceiptDraft draft,
    required String finalVendorName,
    required DateTime finalTransactionDate,
    required double finalTotalAmount,
    required ExpenseCategoryEntity finalCategory,
    double? finalTaxAmount,
    String? finalReceiptNumber,
  }) async {
    try {
      // Cek duplikat berdasarkan nilai FINAL (setelah koreksi user),
      // bukan nilai OCR mentah - user berhak tahu meski sudah mengedit.
      final duplicateId = await _localDataSource.findDuplicateNoteId(
        vendorName: finalVendorName,
        transactionDate: finalTransactionDate,
        totalAmount: finalTotalAmount,
      );

      final model = ExpenseNoteModel(
        id: _localDataSource.newId(),
        taskId: taskId,
        localScanPath: draft.localScanPath,
        vendorName: finalVendorName,
        transactionDate: finalTransactionDate,
        totalAmount: finalTotalAmount,
        taxAmount: finalTaxAmount,
        receiptNumber: finalReceiptNumber,
        category: finalCategory,
        ocrRawText: draft.ocrRawText,
        ocrConfidence: draft.ocrConfidence,
        duplicateOfNoteId: duplicateId,
      );

      final saved = await _localDataSource.persist(model);
      return Right(saved);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, List<ExpenseNoteEntity>>> getNotesByTask(
    String taskId,
  ) async {
    try {
      final notes = await _localDataSource.getNotesByTask(taskId);
      return Right(notes);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  double _averageConfidence(ParsedReceiptResult parsed) {
    final scores = [
      parsed.vendorName.confidence,
      parsed.transactionDate.confidence,
      parsed.totalAmount.confidence,
    ];
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  ExpenseCategoryEntity _mapCategory(ReceiptCategory category) {
    switch (category) {
      case ReceiptCategory.bbm:
        return ExpenseCategoryEntity.bbm;
      case ReceiptCategory.tol:
        return ExpenseCategoryEntity.tol;
      case ReceiptCategory.penginapan:
        return ExpenseCategoryEntity.penginapan;
      case ReceiptCategory.retail:
        return ExpenseCategoryEntity.retail;
      case ReceiptCategory.konsumsi:
        return ExpenseCategoryEntity.konsumsi;
      case ReceiptCategory.transportasiLain:
        return ExpenseCategoryEntity.transportasiLain;
      case ReceiptCategory.lainnya:
        return ExpenseCategoryEntity.lainnya;
    }
  }
}
