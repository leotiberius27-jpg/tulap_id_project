import '../../domain/entities/expense_note_entity.dart';

class ExpenseNoteModel extends ExpenseNoteEntity {
  const ExpenseNoteModel({
    required super.id,
    required super.taskId,
    required super.localScanPath,
    required super.vendorName,
    required super.transactionDate,
    required super.totalAmount,
    required super.category,
    required super.ocrRawText,
    required super.ocrConfidence,
    super.taxAmount,
    super.receiptNumber,
    super.duplicateOfNoteId,
  });

  factory ExpenseNoteModel.fromMap(Map<String, dynamic> map) {
    return ExpenseNoteModel(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      localScanPath: map['localScanPath'] as String,
      vendorName: map['vendorName'] as String,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      taxAmount: map['taxAmount'] != null ? (map['taxAmount'] as num).toDouble() : null,
      receiptNumber: map['receiptNumber'] as String?,
      category: ExpenseCategoryEntity.values.firstWhere(
        (c) => c.name == map['category'],
      ),
      ocrRawText: map['ocrRawText'] as String,
      ocrConfidence: (map['ocrConfidence'] as num).toDouble(),
      duplicateOfNoteId: map['duplicateOfNoteId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'localScanPath': localScanPath,
      'vendorName': vendorName,
      'transactionDate': transactionDate.toIso8601String(),
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'receiptNumber': receiptNumber,
      'category': category.name,
      'ocrRawText': ocrRawText,
      'ocrConfidence': ocrConfidence,
      'duplicateOfNoteId': duplicateOfNoteId,
    };
  }

  /// Payload untuk endpoint `POST /evidence/receipt` - file scan dikirim
  /// terpisah sebagai multipart, sama seperti pola di GeotagPhotoModel.
  Map<String, dynamic> toUploadPayload() {
    return {
      'taskId': taskId,
      'vendorName': vendorName,
      'transactionDate': transactionDate.toIso8601String(),
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'receiptNumber': receiptNumber,
      'category': category.name,
      'ocrRawText': ocrRawText,
      'ocrConfidence': ocrConfidence,
    };
  }
}
