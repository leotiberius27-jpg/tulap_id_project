/// ExpenseCategoryEntity
/// ----------------------------------------------------------------------
/// Kategori pengeluaran operasional kegiatan lapangan Tulap.id.
/// ----------------------------------------------------------------------
enum ExpenseCategoryEntity {
  bbm,
  tol,
  penginapan,
  retail,
  konsumsi,
  transportasiLain,
  atk,
  perlengkapan,
  lainnya;

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
      case ExpenseCategoryEntity.atk:
        return 'ATK / Fotokopi';
      case ExpenseCategoryEntity.perlengkapan:
        return 'Perlengkapan';
      case ExpenseCategoryEntity.lainnya:
        return 'Lainnya';
    }
  }

  static ExpenseCategoryEntity fromString(String? val) {
    if (val == null) return ExpenseCategoryEntity.lainnya;
    final lower = val.toLowerCase();
    for (final cat in ExpenseCategoryEntity.values) {
      if (cat.name.toLowerCase() == lower ||
          cat.label.toLowerCase() == lower ||
          (lower == 'transportasi' && cat == ExpenseCategoryEntity.transportasiLain)) {
        return cat;
      }
    }
    return ExpenseCategoryEntity.lainnya;
  }
}

enum ExpenseSourceEntity {
  camera('Kamera'),
  galleryImport('Import Galeri'),
  manualEntry('Input Manual');

  final String label;
  const ExpenseSourceEntity(this.label);

  static ExpenseSourceEntity fromString(String? val) {
    if (val == null) return ExpenseSourceEntity.camera;
    final lower = val.toLowerCase();
    if (lower.contains('gallery')) return ExpenseSourceEntity.galleryImport;
    if (lower.contains('manual')) return ExpenseSourceEntity.manualEntry;
    return ExpenseSourceEntity.camera;
  }
}

enum ExpenseVerificationStatus {
  ocrExtracted('Hasil OCR'),
  userConfirmed('Dikonfirmasi Petugas'),
  pendingReview('Perlu Ditinjau'),
  synced('Tersinkronisasi');

  final String label;
  const ExpenseVerificationStatus(this.label);

  static ExpenseVerificationStatus fromString(String? val) {
    if (val == null) return ExpenseVerificationStatus.userConfirmed;
    final lower = val.toLowerCase();
    if (lower.contains('ocr')) return ExpenseVerificationStatus.ocrExtracted;
    if (lower.contains('pending')) return ExpenseVerificationStatus.pendingReview;
    if (lower.contains('synced')) return ExpenseVerificationStatus.synced;
    return ExpenseVerificationStatus.userConfirmed;
  }
}

/// ExpenseNoteEntity
/// ----------------------------------------------------------------------
/// Representasi murni satu nota pengeluaran di layer domain Tulap.id.
/// ----------------------------------------------------------------------
class ExpenseNoteEntity {
  final String id;
  final String taskId;
  final String? userId;
  final String localScanPath;
  final String? localOriginalPath;
  final String? remoteScanUrl;

  final String vendorName;
  final DateTime transactionDate;
  final String? transactionTime;
  final double totalAmount;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? serviceCharge;
  final String? receiptNumber;
  final ExpenseCategoryEntity category;
  final String? paymentMethod;
  final String? notes;

  final String ocrRawText;
  final double ocrConfidence;

  final ExpenseSourceEntity source;
  final ExpenseVerificationStatus verificationStatus;
  final String? originalSha256;
  final String? processedSha256;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? serverTimestamp;

  final String? duplicateOfNoteId;
  final String? travelId;

  const ExpenseNoteEntity({
    required this.id,
    required this.taskId,
    this.userId,
    required this.localScanPath,
    this.localOriginalPath,
    this.remoteScanUrl,
    required this.vendorName,
    required this.transactionDate,
    this.transactionTime,
    required this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.serviceCharge,
    this.receiptNumber,
    required this.category,
    this.paymentMethod,
    this.notes,
    required this.ocrRawText,
    required this.ocrConfidence,
    this.source = ExpenseSourceEntity.camera,
    this.verificationStatus = ExpenseVerificationStatus.userConfirmed,
    this.originalSha256,
    this.processedSha256,
    this.syncStatus = 'LOCAL_ONLY',
    DateTime? createdAt,
    this.updatedAt,
    this.serverTimestamp,
    this.duplicateOfNoteId,
    this.travelId,
  }) : createdAt = createdAt ?? transactionDate;

  bool get isPossibleDuplicate => duplicateOfNoteId != null;
  bool get hasReceipt => localScanPath.isNotEmpty || (remoteScanUrl?.isNotEmpty ?? false);
  bool get isManualEntry => source == ExpenseSourceEntity.manualEntry;
  bool get needsManualReview => ocrConfidence < 0.7;

  ExpenseNoteEntity copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? localScanPath,
    String? localOriginalPath,
    String? remoteScanUrl,
    String? vendorName,
    DateTime? transactionDate,
    String? transactionTime,
    double? totalAmount,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? serviceCharge,
    String? receiptNumber,
    ExpenseCategoryEntity? category,
    String? paymentMethod,
    String? notes,
    String? ocrRawText,
    double? ocrConfidence,
    ExpenseSourceEntity? source,
    ExpenseVerificationStatus? verificationStatus,
    String? originalSha256,
    String? processedSha256,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? serverTimestamp,
    String? duplicateOfNoteId,
    String? travelId,
  }) {
    return ExpenseNoteEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      localScanPath: localScanPath ?? this.localScanPath,
      localOriginalPath: localOriginalPath ?? this.localOriginalPath,
      remoteScanUrl: remoteScanUrl ?? this.remoteScanUrl,
      vendorName: vendorName ?? this.vendorName,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      source: source ?? this.source,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      originalSha256: originalSha256 ?? this.originalSha256,
      processedSha256: processedSha256 ?? this.processedSha256,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      duplicateOfNoteId: duplicateOfNoteId ?? this.duplicateOfNoteId,
      travelId: travelId ?? this.travelId,
    );
  }
}
