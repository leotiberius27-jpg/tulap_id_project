import '../../domain/entities/expense_note_entity.dart';

class ExpenseNoteModel extends ExpenseNoteEntity {
  const ExpenseNoteModel({
    required super.id,
    required super.taskId,
    super.userId,
    required super.localScanPath,
    super.localOriginalPath,
    super.remoteScanUrl,
    required super.vendorName,
    required super.transactionDate,
    super.transactionTime,
    required super.totalAmount,
    super.subtotal,
    super.taxAmount,
    super.discountAmount,
    super.serviceCharge,
    super.receiptNumber,
    required super.category,
    super.paymentMethod,
    super.notes,
    required super.ocrRawText,
    required super.ocrConfidence,
    super.source = ExpenseSourceEntity.camera,
    super.verificationStatus = ExpenseVerificationStatus.userConfirmed,
    super.originalSha256,
    super.processedSha256,
    super.syncStatus = 'LOCAL_ONLY',
    super.createdAt,
    super.updatedAt,
    super.serverTimestamp,
    super.duplicateOfNoteId,
    super.travelId,
  });

  factory ExpenseNoteModel.fromEntity(ExpenseNoteEntity entity) {
    return ExpenseNoteModel(
      id: entity.id,
      taskId: entity.taskId,
      userId: entity.userId,
      localScanPath: entity.localScanPath,
      localOriginalPath: entity.localOriginalPath,
      remoteScanUrl: entity.remoteScanUrl,
      vendorName: entity.vendorName,
      transactionDate: entity.transactionDate,
      transactionTime: entity.transactionTime,
      totalAmount: entity.totalAmount,
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      serviceCharge: entity.serviceCharge,
      receiptNumber: entity.receiptNumber,
      category: entity.category,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      ocrRawText: entity.ocrRawText,
      ocrConfidence: entity.ocrConfidence,
      source: entity.source,
      verificationStatus: entity.verificationStatus,
      originalSha256: entity.originalSha256,
      processedSha256: entity.processedSha256,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      serverTimestamp: entity.serverTimestamp,
      duplicateOfNoteId: entity.duplicateOfNoteId,
      travelId: entity.travelId,
    );
  }

  factory ExpenseNoteModel.fromMap(Map<String, dynamic> map) {
    return ExpenseNoteModel(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      userId: map['userId'] as String?,
      localScanPath: map['localScanPath'] as String? ?? '',
      localOriginalPath: map['localOriginalPath'] as String?,
      remoteScanUrl: map['remoteScanUrl'] as String?,
      vendorName: map['vendorName'] as String? ?? 'Nota Tanpa Nama',
      transactionDate: map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'] as String)
          : DateTime.now(),
      transactionTime: map['transactionTime'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      taxAmount: (map['taxAmount'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      serviceCharge: (map['serviceCharge'] as num?)?.toDouble(),
      receiptNumber: map['receiptNumber'] as String?,
      category: ExpenseCategoryEntity.fromString(map['category'] as String?),
      paymentMethod: map['paymentMethod'] as String?,
      notes: map['notes'] as String?,
      ocrRawText: map['ocrRawText'] as String? ?? '',
      ocrConfidence: (map['ocrConfidence'] as num?)?.toDouble() ?? 1.0,
      source: ExpenseSourceEntity.fromString(map['source'] as String?),
      verificationStatus: ExpenseVerificationStatus.fromString(
        map['verificationStatus'] as String?,
      ),
      originalSha256: map['originalSha256'] as String?,
      processedSha256: map['processedSha256'] as String?,
      syncStatus: map['syncStatus'] as String? ?? 'LOCAL_ONLY',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      serverTimestamp: map['serverTimestamp'] != null
          ? DateTime.parse(map['serverTimestamp'] as String)
          : null,
      duplicateOfNoteId: map['duplicateOfNoteId'] as String?,
      travelId: map['travelId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'localScanPath': localScanPath,
      'localOriginalPath': localOriginalPath,
      'remoteScanUrl': remoteScanUrl,
      'vendorName': vendorName,
      'transactionDate': transactionDate.toIso8601String(),
      'transactionTime': transactionTime,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'serviceCharge': serviceCharge,
      'receiptNumber': receiptNumber,
      'category': category.name,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'ocrRawText': ocrRawText,
      'ocrConfidence': ocrConfidence,
      'source': source.name,
      'verificationStatus': verificationStatus.name,
      'originalSha256': originalSha256,
      'processedSha256': processedSha256,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serverTimestamp': serverTimestamp?.toIso8601String(),
      'duplicateOfNoteId': duplicateOfNoteId,
      'travelId': travelId,
    };
  }

  factory ExpenseNoteModel.fromApiJson(Map<String, dynamic> json) {
    return ExpenseNoteModel(
      id: json['id'] as String,
      taskId: (json['taskId'] ?? '') as String,
      userId: json['ownerId'] as String?,
      localScanPath: json['scanUrl'] as String? ?? '',
      remoteScanUrl: json['scanUrl'] as String?,
      vendorName: json['vendorName'] as String? ?? 'Nota',
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      receiptNumber: json['receiptNumber'] as String?,
      category: ExpenseCategoryEntity.fromString(json['category'] as String?),
      ocrRawText: json['ocrRawText'] as String? ?? '',
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble() ?? 1.0,
      verificationStatus: ExpenseVerificationStatus.synced,
      syncStatus: 'SYNCED',
      travelId: (json['travelMissionId'] ?? json['travelId']) as String?,
      serverTimestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUploadPayload() {
    return {
      'id': id,
      'taskId': taskId,
      'vendorName': vendorName,
      'transactionDate': transactionDate.toIso8601String(),
      'transactionTime': transactionTime,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'serviceCharge': serviceCharge,
      'receiptNumber': receiptNumber,
      'category': category.name,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'ocrRawText': ocrRawText,
      'ocrConfidence': ocrConfidence,
      'originalSha256': originalSha256,
      'processedSha256': processedSha256,
      'source': source.name,
    };
  }
}
