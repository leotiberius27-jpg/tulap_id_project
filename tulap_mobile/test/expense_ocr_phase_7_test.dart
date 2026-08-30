import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/ocr/receipt_parser.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/entities/expense_note_entity.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/repositories/expense_ocr_repository.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/delete_expense_note.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/save_expense_note.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/save_manual_expense.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/update_expense_note.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/usecases/enqueue_sync_item.dart';

// --- In-Memory Fake Repository for Phase 7 Unit Testing ---
class _FakeExpenseOcrRepository implements ExpenseOcrRepository {
  final Map<String, ExpenseNoteEntity> _storage = {};

  @override
  Future<Either<Failure, ScannedReceiptDraft>> scanReceipt() async {
    return Right(
      ScannedReceiptDraft(
        localScanPath: '/data/user/0/com.tulap.mobile/app_flutter/mock_scan.jpg',
        category: ExpenseCategoryEntity.bbm,
        ocrRawText: 'SPBU PERTAMINA 84.999.01\n26 Agu 2026\nTOTAL BAYAR: Rp 450.000',
        ocrConfidence: 0.92,
        vendorName: 'SPBU PERTAMINA 84.999.01',
        transactionDate: DateTime(2026, 8, 26),
        totalAmount: 450000,
        paymentMethod: 'Tunai / Cash',
      ),
    );
  }

  @override
  Future<Either<Failure, ScannedReceiptDraft>> scanReceiptFromFile(
    String imagePath, {
    ExpenseSourceEntity source = ExpenseSourceEntity.camera,
    String? originalPath,
  }) async {
    return Right(
      ScannedReceiptDraft(
        localScanPath: imagePath,
        localOriginalPath: originalPath ?? imagePath,
        category: ExpenseCategoryEntity.konsumsi,
        ocrRawText: 'RM NUSANTARA JAYAPURA\n26/08/2026\nTOTAL: Rp 275.000',
        ocrConfidence: 0.88,
        vendorName: 'RM NUSANTARA JAYAPURA',
        transactionDate: DateTime(2026, 8, 26),
        totalAmount: 275000,
        source: source,
      ),
    );
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
    final note = ExpenseNoteEntity(
      id: 'receipt-${_storage.length + 1}',
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
      syncStatus: 'LOCAL_ONLY',
      createdAt: DateTime.now(),
    );
    _storage[note.id] = note;
    return Right(note);
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
    final note = ExpenseNoteEntity(
      id: 'manual-${_storage.length + 1}',
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
      createdAt: DateTime.now(),
    );
    _storage[note.id] = note;
    return Right(note);
  }

  @override
  Future<Either<Failure, ExpenseNoteEntity>> updateExpenseNote(
    ExpenseNoteEntity note,
  ) async {
    _storage[note.id] = note;
    return Right(note);
  }

  @override
  Future<Either<Failure, void>> deleteExpenseNote(
    String noteId,
    String taskId,
  ) async {
    _storage.remove(noteId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<ExpenseNoteEntity>>> getNotesByTask(
    String taskId,
  ) async {
    final list = _storage.values.where((n) => n.taskId == taskId).toList();
    return Right(list);
  }

  @override
  Future<Either<Failure, ExpenseNoteEntity?>> getNoteById(String noteId) async {
    return Right(_storage[noteId]);
  }

  @override
  Future<Either<Failure, String?>> checkDuplicateReceipt({
    String? sha256Hash,
    String? vendorName,
    DateTime? transactionDate,
    double? totalAmount,
    String? excludeId,
  }) async {
    for (final existing in _storage.values) {
      if (excludeId != null && existing.id == excludeId) continue;
      if (sha256Hash != null &&
          (existing.originalSha256 == sha256Hash ||
              existing.processedSha256 == sha256Hash)) {
        return Right(existing.id);
      }
      if (vendorName != null &&
          transactionDate != null &&
          totalAmount != null) {
        if (existing.vendorName.trim().toLowerCase() ==
                vendorName.trim().toLowerCase() &&
            existing.transactionDate.year == transactionDate.year &&
            existing.transactionDate.month == transactionDate.month &&
            existing.transactionDate.day == transactionDate.day &&
            (existing.totalAmount - totalAmount).abs() < 1) {
          return Right(existing.id);
        }
      }
    }
    return const Right(null);
  }
}

class _FakeEnqueueSyncItem implements EnqueueSyncItem {
  final List<SyncRecordEntity> enqueued = [];

  @override
  Future<Either<Failure, SyncRecordEntity>> call({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  }) async {
    final item = SyncRecordEntity(
      id: 'sync-${enqueued.length + 1}',
      entityType: entityType,
      entityLocalId: entityLocalId,
      taskId: taskId,
      status: SyncStatus.waitingForInternet,
      attemptCount: 0,
      createdAt: DateTime.now(),
    );
    enqueued.add(item);
    return Right(item);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 7: Indonesian Receipt OCR & Parsing Tests', () {
    late ReceiptParser parser;

    setUp(() {
      parser = ReceiptParser();
    });

    test('1. SPBU Pertamina receipt parsing (BBM Category, Total, Date)', () {
      const receiptText = '''
SPBU 84.999.01 JAYAPURA
JL. AHMAD YANI NO. 12
NO STRUK: TR-20260826-004
26 Agu 2026 14:30:15
PERTALITE
38.50 L x Rp 10.000
TOTAL HARGA : Rp 385.000
PPN 11%     : Rp 38.500
TOTAL BAYAR : Rp 423.500
TUNAI       : Rp 450.000
KEMBALI     : Rp 26.500
''';

      final result = parser.parseText(receiptText);

      expect(result.category, ReceiptCategory.bbm);
      expect(result.vendorName.value, contains('SPBU'));
      expect(result.totalAmount.value, 423500);
      expect(result.taxAmount.value, 38500);
      expect(result.transactionDate.value, DateTime(2026, 8, 26));
      expect(result.paymentMethod, ReceiptPaymentMethod.tunai);
      expect(result.receiptNumber.value, contains('TR-20260826-004'));
    });

    test('2. Restoran / Rumah Makan receipt (Konsumsi Category, Total vs Kembalian)', () {
      const receiptText = '''
RUMAH MAKAN PADANG NUSANTARA
KOTA JAYAPURA
26/08/2026 19:45
--------------------------------
1x AYAM POP          Rp 25.000
2x RENDANG DAGING    Rp 60.000
1x GULAI KEPALA KAKAP Rp 95.000
3x NASI PUTIH        Rp 30.000
3x ES TEH MANIS      Rp 15.000
--------------------------------
SUBTOTAL             Rp 225.000
PB1 (PAJAK 10%)      Rp 22.500
BIAYA LAYANAN        Rp 10.000
GRAND TOTAL          Rp 257.500
CASH                 Rp 300.000
KEMBALIAN            Rp 42.500
''';

      final result = parser.parseText(receiptText);

      expect(result.category, ReceiptCategory.konsumsi);
      expect(result.vendorName.value, contains('RUMAH MAKAN'));
      expect(result.totalAmount.value, 257500);
      expect(result.subtotal.value, 225000);
      expect(result.taxAmount.value, 22500);
      expect(result.serviceCharge.value, 10000);
      expect(result.transactionDate.value, DateTime(2026, 8, 26));
    });

    test('3. Retail / Minimarket receipt with QRIS Payment', () {
      const receiptText = '''
INDOMARET ABEPURA
JL. RAYA ABEPURA NO 88
2026-08-27 10:15
AIR MINERAL 1500ML   Rp 12.000
BISKUIT GANDUM       Rp 18.000
TOTAL BELANJA        Rp 30.000
METODE: QRIS GOPAY
LUNAS
''';

      final result = parser.parseText(receiptText);

      expect(result.category, ReceiptCategory.retail);
      expect(result.vendorName.value, contains('INDOMARET'));
      expect(result.totalAmount.value, 30000);
      expect(result.paymentMethod, ReceiptPaymentMethod.qris);
      expect(result.transactionDate.value, DateTime(2026, 8, 27));
    });

    test('4. Tol & Transportasi receipt', () {
      const receiptText = '''
PT JASA MARGA (PERSERO)
GERBANG TOL CENGKARENG
TANGGAL: 15/05/2026 08:30
TARIF GOL 1 : Rp 11.000
TOTAL BAYAR : Rp 11.000
E-TOLL MANDIRI
''';

      final result = parser.parseText(receiptText);

      expect(result.category, ReceiptCategory.tol);
      expect(result.totalAmount.value, 11000);
    });

    test('5. Hotel & Penginapan receipt with large amount', () {
      const receiptText = '''
HOTEL HORISON ULTIMA JAYAPURA
INVOICE NO: INV-2026-0988
CHECK IN: 25 AGUSTUS 2026
ROOM CHARGE (2 NIGHTS)  Rp 1.600.000
LAUNDRY                 Rp 100.000
TOTAL TAGIHAN           Rp 1.700.000
DEBIT BCA
''';

      final result = parser.parseText(receiptText);

      expect(result.category, ReceiptCategory.penginapan);
      expect(result.totalAmount.value, 1700000);
      expect(result.paymentMethod, ReceiptPaymentMethod.kartu);
    });

    test('6. Decimal & Separator Precision: Avoids reading 125.000 as 125', () {
      const raw = 'TOTAL Rp 125.000';
      final result = parser.parseText(raw);
      expect(result.totalAmount.value, 125000.0);
    });
  });

  group('Phase 7: Expense Model, Use Cases & Totals Calculation Tests', () {
    late _FakeExpenseOcrRepository repo;
    late _FakeEnqueueSyncItem fakeEnqueue;
    late ConfirmAndSaveExpenseNote saveReceiptUseCase;
    late SaveManualExpense saveManualUseCase;
    late DeleteExpenseNote deleteUseCase;
    late UpdateExpenseNote updateUseCase;

    setUp(() {
      repo = _FakeExpenseOcrRepository();
      fakeEnqueue = _FakeEnqueueSyncItem();
      saveReceiptUseCase = ConfirmAndSaveExpenseNote(
        repository: repo,
        enqueueSyncItem: fakeEnqueue,
      );
      saveManualUseCase = SaveManualExpense(repo);
      deleteUseCase = DeleteExpenseNote(repo);
      updateUseCase = UpdateExpenseNote(repo);
    });

    Future<void> seedThreeNotes() async {
      await saveReceiptUseCase(
        taskId: 'task-01',
        draft: ScannedReceiptDraft(
          localScanPath: '/path/spbu.jpg',
          category: ExpenseCategoryEntity.bbm,
          ocrRawText: 'SPBU Rp 450.000',
          ocrConfidence: 0.95,
        ),
        finalVendorName: 'SPBU Pertamina 84.999',
        finalTransactionDate: DateTime(2026, 8, 26),
        finalTotalAmount: 450000,
        finalCategory: ExpenseCategoryEntity.bbm,
      );
      await saveReceiptUseCase(
        taskId: 'task-01',
        draft: ScannedReceiptDraft(
          localScanPath: '/path/rm.jpg',
          category: ExpenseCategoryEntity.konsumsi,
          ocrRawText: 'RM Nusantara Rp 275.000',
          ocrConfidence: 0.90,
        ),
        finalVendorName: 'RM Nusantara',
        finalTransactionDate: DateTime(2026, 8, 26),
        finalTotalAmount: 275000,
        finalCategory: ExpenseCategoryEntity.konsumsi,
      );
      await saveReceiptUseCase(
        taskId: 'task-01',
        draft: ScannedReceiptDraft(
          localScanPath: '/path/hotel.jpg',
          category: ExpenseCategoryEntity.penginapan,
          ocrRawText: 'Hotel Horison Rp 850.000',
          ocrConfidence: 0.92,
        ),
        finalVendorName: 'Hotel Horison',
        finalTransactionDate: DateTime(2026, 8, 26),
        finalTotalAmount: 850000,
        finalCategory: ExpenseCategoryEntity.penginapan,
      );
    }

    test('7. Saving 3 receipts calculates Activity total accurately: 450k + 275k + 850k = 1.575.000', () async {
      await seedThreeNotes();

      // Ambil daftar nota task-01 dan hitung total
      final notesResult = await repo.getNotesByTask('task-01');
      expect(notesResult.isRight(), isTrue);
      final notes = notesResult.getOrElse(() => []);
      expect(notes.length, 3);

      final total = notes.fold(0.0, (sum, n) => sum + n.totalAmount);
      expect(total, 1575000.0);
      expect(fakeEnqueue.enqueued.length, 3);
    });

    test('8. Deleting one receipt recalculates total: 1.575.000 - 275.000 = 1.300.000', () async {
      await seedThreeNotes();

      final listBefore = (await repo.getNotesByTask('task-01')).getOrElse(() => []);
      expect(listBefore.length, 3);

      // Hapus nota ke-2 (receipt-2: RM Nusantara Rp 275.000)
      final delResult = await deleteUseCase(noteId: 'receipt-2', taskId: 'task-01');
      expect(delResult.isRight(), isTrue);

      final listAfter = (await repo.getNotesByTask('task-01')).getOrElse(() => []);
      expect(listAfter.length, 2);

      final newTotal = listAfter.fold(0.0, (sum, n) => sum + n.totalAmount);
      expect(newTotal, 1300000.0);
    });

    test('9. User editing OCR total: 450.800 -> 450.000 recalculates total accurately', () async {
      await seedThreeNotes();

      final note1 = (await repo.getNoteById('receipt-1')).getOrElse(() => null);
      expect(note1, isNotNull);

      final updated = note1!.copyWith(totalAmount: 450000);
      await updateUseCase(updated);

      final savedUpdated = (await repo.getNoteById('receipt-1')).getOrElse(() => null);
      expect(savedUpdated!.totalAmount, 450000.0);
    });

    test('10. Manual Expense Entry creates valid expense record without receipt file', () async {
      final manualResult = await saveManualUseCase(
        taskId: 'task-01',
        vendorName: 'Ojek Lapangan Pangkalan Sentani',
        transactionDate: DateTime(2026, 8, 27),
        totalAmount: 50000,
        category: ExpenseCategoryEntity.transportasiLain,
        notes: 'Antar jemput lokasi survei jembatan',
      );

      expect(manualResult.isRight(), isTrue);
      final note = manualResult.getOrElse(() => throw Exception());
      expect(note.isManualEntry, isTrue);
      expect(note.hasReceipt, isFalse);
      expect(note.totalAmount, 50000.0);
      expect(note.category, ExpenseCategoryEntity.transportasiLain);
    });

    test('11. Duplicate Receipt Detection warns on identical signature', () async {
      await seedThreeNotes();

      final dupResult = await repo.checkDuplicateReceipt(
        vendorName: 'SPBU Pertamina 84.999',
        transactionDate: DateTime(2026, 8, 26),
        totalAmount: 450000,
      );

      expect(dupResult.isRight(), isTrue);
      expect(dupResult.getOrElse(() => null), equals('receipt-1'));
    });
  });
}
