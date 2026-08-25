import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/ocr/receipt_ocr_engine.dart';
import '../../../../core/ocr/receipt_parser.dart';
import '../models/expense_note_model.dart';

const int _kTargetMaxFileSizeBytes =
    300 * 1024; // ~300KB, sama seperti foto geotag

/// ExpenseOcrLocalDataSource
/// ----------------------------------------------------------------------
/// Menggabungkan tiga hal teknis: kamera (`camera` package), OCR
/// (`ReceiptOcrEngine`), dan penyimpanan lokal (SQLite). Method di sini
/// mengembalikan tipe intermediate (bukan langsung ExpenseNoteModel)
/// untuk langkah scan, karena hasil OCR mentah harus melalui Review
/// Sheet dulu sebelum jadi data final.
/// ----------------------------------------------------------------------
class ExpenseOcrLocalDataSource {
  final ReceiptOcrEngine _ocrEngine;
  final ReceiptParser _parser;
  final Database _database;
  final Uuid _uuid = const Uuid();

  ExpenseOcrLocalDataSource({
    required ReceiptOcrEngine ocrEngine,
    required ReceiptParser parser,
    required Database database,
  }) : _ocrEngine = ocrEngine,
       _parser = parser,
       _database = database;

  /// Memfoto nota dari [controller] kamera, mengompresnya, lalu
  /// menjalankan OCR + parsing. TIDAK menyimpan apa pun ke tabel
  /// `expense_notes` di tahap ini - hanya mengembalikan hasil parsing
  /// sebagai draft untuk Review Sheet.
  Future<ParsedReceiptResult> captureAndScan(
    CameraController controller,
  ) async {
    if (!controller.value.isInitialized) {
      throw CameraException('NOT_INITIALIZED', 'Kamera belum siap digunakan.');
    }

    final rawFile = await controller.takePicture();
    final compressedPath = await _compressImage(rawFile.path);

    final recognizedText = await _ocrEngine.recognizeText(compressedPath);
    final parsed = _parser.parse(recognizedText);

    // Simpan path terkompresi di hasil parsing lewat closure sederhana -
    // untuk kesederhanaan, path disimpan terpisah dan digabung di
    // repository saat confirmAndSave dipanggil.
    _lastCompressedPath = compressedPath;

    // Hapus file mentah, sisakan versi kompresi saja.
    final rawFileOnDisk = File(rawFile.path);
    if (await rawFileOnDisk.exists()) {
      await rawFileOnDisk.delete();
    }

    return parsed;
  }

  // Penyimpanan sementara path terkompresi dari scan terakhir - dibaca
  // oleh repository segera setelah captureAndScan() selesai, dalam
  // alur yang sama (bukan lintas sesi).
  String? _lastCompressedPath;
  String? get lastCompressedPath => _lastCompressedPath;

  Future<String> _compressImage(String originalPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath =
        '${dir.path}/tulap_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int quality = 85;
    XFile? result;
    do {
      result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        quality: quality,
        keepExif: false,
      );
      if (result == null) break;
      final size = await File(result.path).length();
      if (size <= _kTargetMaxFileSizeBytes || quality <= 40) break;
      quality -= 15;
    } while (true);

    return result?.path ?? originalPath;
  }

  /// Deteksi duplikat sederhana: hash dari kombinasi vendor + tanggal +
  /// nominal (dinormalisasi ke lowercase/trim). Nota yang sama difoto
  /// dua kali (baik sengaja maupun tidak sengaja) akan menghasilkan
  /// hash identik, sesuai kebutuhan "Duplicate receipt detection"
  /// (Bagian 12 dokumen requirement awal & Bagian 37 spesifikasi).
  Future<String?> findDuplicateNoteId({
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
  }) async {
    final signature = _buildDuplicateSignature(
      vendorName: vendorName,
      transactionDate: transactionDate,
      totalAmount: totalAmount,
    );

    final rows = await _database.query('expense_notes');
    for (final row in rows) {
      final existing = ExpenseNoteModel.fromMap(row);
      final existingSignature = _buildDuplicateSignature(
        vendorName: existing.vendorName,
        transactionDate: existing.transactionDate,
        totalAmount: existing.totalAmount,
      );
      if (existingSignature == signature) {
        return existing.id;
      }
    }
    return null;
  }

  String _buildDuplicateSignature({
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
  }) {
    final normalizedVendor = vendorName.trim().toLowerCase();
    final dateOnly =
        '${transactionDate.year}-${transactionDate.month}-${transactionDate.day}';
    final raw = '$normalizedVendor|$dateOnly|${totalAmount.toStringAsFixed(0)}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Future<ExpenseNoteModel> persist(ExpenseNoteModel model) async {
    await _database.insert('expense_notes', model.toMap());
    return model;
  }

  Future<List<ExpenseNoteModel>> getNotesByTask(String taskId) async {
    final rows = await _database.query(
      'expense_notes',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'transactionDate DESC',
    );
    return rows.map((row) => ExpenseNoteModel.fromMap(row)).toList();
  }

  String newId() => _uuid.v4();
}
