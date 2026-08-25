/// ExpenseCategoryEntity
/// ----------------------------------------------------------------------
/// Selaras 1:1 dengan enum ExpenseCategory di skema Prisma backend.
/// ----------------------------------------------------------------------
enum ExpenseCategoryEntity {
  bbm,
  tol,
  penginapan,
  retail,
  konsumsi,
  transportasiLain,
  lainnya,
}

extension ExpenseCategoryEntityX on ExpenseCategoryEntity {
  String get label {
    switch (this) {
      case ExpenseCategoryEntity.bbm:
        return 'BBM';
      case ExpenseCategoryEntity.tol:
        return 'Tol';
      case ExpenseCategoryEntity.penginapan:
        return 'Penginapan';
      case ExpenseCategoryEntity.retail:
        return 'Retail';
      case ExpenseCategoryEntity.konsumsi:
        return 'Konsumsi';
      case ExpenseCategoryEntity.transportasiLain:
        return 'Transportasi';
      case ExpenseCategoryEntity.lainnya:
        return 'Lainnya';
    }
  }
}

/// ExpenseNoteEntity
/// ----------------------------------------------------------------------
/// Representasi murni satu nota pengeluaran di layer domain. Field
/// selaras dengan tabel `Expense_Note` di skema Prisma backend.
/// ----------------------------------------------------------------------
class ExpenseNoteEntity {
  final String id;
  final String taskId;
  final String localScanPath;

  final String vendorName;
  final DateTime transactionDate;
  final double totalAmount;
  final double? taxAmount;
  final String? receiptNumber;
  final ExpenseCategoryEntity category;

  final String ocrRawText;
  final double ocrConfidence; // Rata-rata confidence seluruh field kunci

  final String?
  duplicateOfNoteId; // Terisi jika terdeteksi kemungkinan duplikat

  const ExpenseNoteEntity({
    required this.id,
    required this.taskId,
    required this.localScanPath,
    required this.vendorName,
    required this.transactionDate,
    required this.totalAmount,
    required this.category,
    required this.ocrRawText,
    required this.ocrConfidence,
    this.taxAmount,
    this.receiptNumber,
    this.duplicateOfNoteId,
  });

  bool get isPossibleDuplicate => duplicateOfNoteId != null;

  /// Sesuai Bagian 13: field dengan confidence rendah perlu ditinjau
  /// manual - jika confidence keseluruhan rendah, tampilkan badge
  /// "Perlu Dicek" alih-alih "OCR Berhasil" (Bagian 25).
  bool get needsManualReview => ocrConfidence < 0.7;
}
