import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/ocr/receipt_image_processor.dart';
import '../../../../core/ocr/receipt_parser.dart';
import '../../../task_detail/data/datasources/timeline_local_datasource.dart';
import '../../../task_detail/data/models/timeline_event_model.dart';
import '../../../task_detail/domain/entities/timeline_event_entity.dart';
import '../../../sync_queue/data/datasources/sync_local_datasource.dart';
import '../../../sync_queue/data/models/sync_record_model.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';
import '../datasources/expense_ocr_local_datasource.dart';
import '../models/expense_note_model.dart';

class OcrScanFailure extends Failure {
  const OcrScanFailure([
    super.message = 'Gagal membaca nota. Coba foto ulang atau perjelas gambar.',
  ]);
}

class DuplicateReceiptFailure extends Failure {
  const DuplicateReceiptFailure([
    super.message = 'Nota ini tampaknya sudah pernah digunakan.',
  ]);
}

class ExpenseOcrRepositoryImpl implements ExpenseOcrRepository {
  final ExpenseOcrLocalDataSource _localDataSource;
  final SyncLocalDataSource? _syncQueueLocalDataSource;
  final TimelineLocalDataSource? _timelineLocalDataSource;
  final ReceiptImageProcessor _imageProcessor = ReceiptImageProcessor();
  final Uuid _uuid = const Uuid();
  CameraController? _cameraController;

  ExpenseOcrRepositoryImpl({
    required ExpenseOcrLocalDataSource localDataSource,
    SyncLocalDataSource? syncQueueLocalDataSource,
    TimelineLocalDataSource? timelineLocalDataSource,
    CameraController? cameraController,
  }) : _localDataSource = localDataSource,
       _syncQueueLocalDataSource = syncQueueLocalDataSource,
       _timelineLocalDataSource = timelineLocalDataSource,
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

      final hash = await ReceiptImageProcessor.calculateSha256(compressedPath);

      final draft = ScannedReceiptDraft(
        localScanPath: compressedPath,
        localOriginalPath: compressedPath,
        originalSha256: hash,
        processedSha256: hash,
        vendorName: parsed.vendorName.value,
        transactionDate: parsed.transactionDate.value,
        transactionTime: parsed.transactionTime.value,
        totalAmount: parsed.totalAmount.value,
        subtotal: parsed.subtotal.value,
        taxAmount: parsed.taxAmount.value,
        discountAmount: parsed.discountAmount.value,
        serviceCharge: parsed.serviceCharge.value,
        receiptNumber: parsed.receiptNumber.value,
        category: _mapCategory(parsed.category),
        paymentMethod: parsed.paymentMethod.label,
        ocrRawText: parsed.rawText,
        ocrConfidence: parsed.averageConfidence,
        source: ExpenseSourceEntity.camera,
      );

      return Right(draft);
    } on CameraException catch (e) {
      return Left(CameraFailure(e.description ?? 'Kendala sensor kamera nota.'));
    } catch (_) {
      return const Left(OcrScanFailure());
    }
  }

  @override
  Future<Either<Failure, ScannedReceiptDraft>> scanReceiptFromFile(
    String imagePath, {
    ExpenseSourceEntity source = ExpenseSourceEntity.camera,
    String? originalPath,
  }) async {
    try {
      final parsed = await _localDataSource.scanImageFile(imagePath);
      final compressedPath = _localDataSource.lastCompressedPath ?? imagePath;
      final hash = await ReceiptImageProcessor.calculateSha256(compressedPath);
      final origHash = originalPath != null
          ? await ReceiptImageProcessor.calculateSha256(originalPath)
          : hash;

      final draft = ScannedReceiptDraft(
        localScanPath: compressedPath,
        localOriginalPath: originalPath ?? compressedPath,
        originalSha256: origHash,
        processedSha256: hash,
        vendorName: parsed.vendorName.value,
        transactionDate: parsed.transactionDate.value,
        transactionTime: parsed.transactionTime.value,
        totalAmount: parsed.totalAmount.value,
        subtotal: parsed.subtotal.value,
        taxAmount: parsed.taxAmount.value,
        discountAmount: parsed.discountAmount.value,
        serviceCharge: parsed.serviceCharge.value,
        receiptNumber: parsed.receiptNumber.value,
        category: _mapCategory(parsed.category),
        paymentMethod: parsed.paymentMethod.label,
        ocrRawText: parsed.rawText,
        ocrConfidence: parsed.averageConfidence,
        source: source,
      );

      return Right(draft);
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
    try {
      final duplicateId = await _localDataSource.findDuplicateNoteId(
        vendorName: finalVendorName,
        transactionDate: finalTransactionDate,
        totalAmount: finalTotalAmount,
      );

      final noteId = _localDataSource.newId();
      final now = DateTime.now();

      final model = ExpenseNoteModel(
        id: noteId,
        taskId: taskId,
        localScanPath: draft.localScanPath,
        localOriginalPath: draft.localOriginalPath,
        vendorName: finalVendorName,
        transactionDate: finalTransactionDate,
        transactionTime: finalTransactionTime ?? draft.transactionTime,
        totalAmount: finalTotalAmount,
        subtotal: finalSubtotal ?? draft.subtotal,
        taxAmount: finalTaxAmount ?? draft.taxAmount,
        discountAmount: finalDiscountAmount ?? draft.discountAmount,
        serviceCharge: finalServiceCharge ?? draft.serviceCharge,
        receiptNumber: finalReceiptNumber ?? draft.receiptNumber,
        category: finalCategory,
        paymentMethod: finalPaymentMethod ?? draft.paymentMethod,
        notes: finalNotes,
        ocrRawText: draft.ocrRawText,
        ocrConfidence: draft.ocrConfidence,
        source: draft.source,
        verificationStatus: ExpenseVerificationStatus.userConfirmed,
        originalSha256: draft.originalSha256,
        processedSha256: draft.processedSha256,
        syncStatus: 'LOCAL_ONLY',
        createdAt: now,
        duplicateOfNoteId: duplicateId,
      );

      final saved = await _localDataSource.persist(model);

      // Enqueue to outbox sync queue
      if (_syncQueueLocalDataSource != null) {
        try {
          await _syncQueueLocalDataSource!.insertRecord(
            entityType: SyncEntityType.expenseNote,
            entityLocalId: saved.id,
            taskId: taskId,
          );
        } catch (_) {}
      }

      // Record to activity timeline
      if (_timelineLocalDataSource != null) {
        try {
          await _timelineLocalDataSource!.saveEvent(
            TimelineEventModel(
              id: _uuid.v4(),
              taskId: taskId,
              eventType: TimelineEventType.receiptScanned,
              title: 'Nota ${saved.category.label} Dipindai',
              description:
                  '${saved.vendorName} — Rp ${saved.totalAmount.toStringAsFixed(0)}',
              eventTimestamp: now,
              metadata: {
                'expenseNoteId': saved.id,
                'vendorName': saved.vendorName,
                'totalAmount': saved.totalAmount,
                'category': saved.category.name,
              },
            ),
          );
        } catch (_) {}
      }

      return Right(saved);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, ExpenseNoteEntity>> saveManualExpense({
    required String taskId,
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    String? notes,
    String? paymentMethod,
  }) async {
    try {
      final noteId = _localDataSource.newId();
      final now = DateTime.now();

      final model = ExpenseNoteModel(
        id: noteId,
        taskId: taskId,
        localScanPath: '',
        vendorName: vendorName,
        transactionDate: transactionDate,
        totalAmount: totalAmount,
        category: category,
        notes: notes,
        paymentMethod: paymentMethod ?? 'Tunai / Cash',
        ocrRawText: '[INPUT_MANUAL]',
        ocrConfidence: 1.0,
        source: ExpenseSourceEntity.manualEntry,
        verificationStatus: ExpenseVerificationStatus.userConfirmed,
        syncStatus: 'LOCAL_ONLY',
        createdAt: now,
      );

      final saved = await _localDataSource.persist(model);

      if (_syncQueueLocalDataSource != null) {
        try {
          await _syncQueueLocalDataSource!.insertRecord(
            entityType: SyncEntityType.expenseNote,
            entityLocalId: saved.id,
            taskId: taskId,
          );
        } catch (_) {}
      }

      if (_timelineLocalDataSource != null) {
        try {
          await _timelineLocalDataSource!.saveEvent(
            TimelineEventModel(
              id: _uuid.v4(),
              taskId: taskId,
              eventType: TimelineEventType.expenseRecorded,
              title: 'Pengeluaran Manual ${saved.category.label}',
              description:
                  '${saved.vendorName} — Rp ${saved.totalAmount.toStringAsFixed(0)}',
              eventTimestamp: now,
              metadata: {
                'expenseNoteId': saved.id,
                'vendorName': saved.vendorName,
                'totalAmount': saved.totalAmount,
                'isManual': true,
              },
            ),
          );
        } catch (_) {}
      }

      return Right(saved);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, ExpenseNoteEntity>> updateExpenseNote(
    ExpenseNoteEntity note,
  ) async {
    try {
      final updated = await _localDataSource.update(
        ExpenseNoteModel.fromEntity(
          note.copyWith(updatedAt: DateTime.now()),
        ),
      );
      return Right(updated);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpenseNote(
    String noteId,
    String taskId,
  ) async {
    try {
      await _localDataSource.delete(noteId);
      return const Right(null);
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

  @override
  Future<Either<Failure, ExpenseNoteEntity?>> getNoteById(String noteId) async {
    try {
      final note = await _localDataSource.getNoteById(noteId);
      return Right(note);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, String?>> checkDuplicateReceipt({
    String? sha256Hash,
    String? vendorName,
    DateTime? transactionDate,
    double? totalAmount,
    String? excludeId,
  }) async {
    try {
      if (sha256Hash != null && sha256Hash.isNotEmpty) {
        final hashMatch = await _localDataSource.findDuplicateByHash(sha256Hash);
        if (hashMatch != null && (excludeId == null || hashMatch != excludeId)) {
          return Right(hashMatch);
        }
      }

      if (vendorName != null && transactionDate != null && totalAmount != null) {
        final fuzzyMatch = await _localDataSource.findDuplicateNoteId(
          vendorName: vendorName,
          transactionDate: transactionDate,
          totalAmount: totalAmount,
          excludeId: excludeId,
        );
        return Right(fuzzyMatch);
      }

      return const Right(null);
    } catch (_) {
      return const Right(null);
    }
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
      case ReceiptCategory.atk:
        return ExpenseCategoryEntity.atk;
      case ReceiptCategory.perlengkapan:
        return ExpenseCategoryEntity.perlengkapan;
      case ReceiptCategory.lainnya:
        return ExpenseCategoryEntity.lainnya;
    }
  }
}
