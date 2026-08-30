import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_note_entity.dart';

/// ScannedReceiptDraft
/// ----------------------------------------------------------------------
/// Hasil scan mentah beserta kandidat field terstruktur sebelum
/// dikonfirmasi oleh pengguna di halaman Periksa Nota.
/// ----------------------------------------------------------------------
class ScannedReceiptDraft {
  final String localScanPath;
  final String? localOriginalPath;
  final String? originalSha256;
  final String? processedSha256;
  final String? vendorName;
  final DateTime? transactionDate;
  final String? transactionTime;
  final double? totalAmount;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? serviceCharge;
  final String? receiptNumber;
  final ExpenseCategoryEntity category;
  final String? paymentMethod;
  final String ocrRawText;
  final double ocrConfidence;
  final ExpenseSourceEntity source;

  const ScannedReceiptDraft({
    required this.localScanPath,
    this.localOriginalPath,
    this.originalSha256,
    this.processedSha256,
    required this.category,
    required this.ocrRawText,
    required this.ocrConfidence,
    this.vendorName,
    this.transactionDate,
    this.transactionTime,
    this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.serviceCharge,
    this.receiptNumber,
    this.paymentMethod,
    this.source = ExpenseSourceEntity.camera,
  });

  bool get needsReview =>
      ocrConfidence < 0.7 ||
      vendorName == null ||
      transactionDate == null ||
      totalAmount == null;
}

/// ExpenseOcrRepository (interface/kontrak domain)
/// ----------------------------------------------------------------------
abstract class ExpenseOcrRepository {
  /// Memfoto nota dari sensor kamera aktif lalu menjalankan OCR
  Future<Either<Failure, ScannedReceiptDraft>> scanReceipt();

  /// Menjalankan OCR pada file gambar yang ada (misal dari Galeri atau hasil crop)
  Future<Either<Failure, ScannedReceiptDraft>> scanReceiptFromFile(
    String imagePath, {
    ExpenseSourceEntity source = ExpenseSourceEntity.camera,
    String? originalPath,
  });

  /// Menyimpan hasil yang sudah dikonfirmasi/diedit user sebagai
  /// ExpenseNoteEntity permanen, termasuk pengecekan duplikat & outbox sync.
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
  });

  /// Menyimpan pengeluaran manual tanpa bukti fisik nota
  Future<Either<Failure, ExpenseNoteEntity>> saveManualExpense({
    required String taskId,
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    String? notes,
    String? paymentMethod,
  });

  /// Memperbarui rincian nota yang sudah tersimpan
  Future<Either<Failure, ExpenseNoteEntity>> updateExpenseNote(
    ExpenseNoteEntity note,
  );

  /// Menghapus nota secara aman dan memperbarui antrian sinkronisasi
  Future<Either<Failure, void>> deleteExpenseNote(String noteId, String taskId);

  /// Mengambil semua nota milik suatu kegiatan
  Future<Either<Failure, List<ExpenseNoteEntity>>> getNotesByTask(
    String taskId,
  );

  /// Mengambil satu nota berdasarkan ID
  Future<Either<Failure, ExpenseNoteEntity?>> getNoteById(String noteId);

  /// Memeriksa apakah nota terduga duplikat (berdasarkan hash atau vendor+tanggal+nominal)
  Future<Either<Failure, String?>> checkDuplicateReceipt({
    String? sha256Hash,
    String? vendorName,
    DateTime? transactionDate,
    double? totalAmount,
    String? excludeId,
  });
}
