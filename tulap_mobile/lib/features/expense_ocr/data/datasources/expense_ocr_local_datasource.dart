import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/ocr/receipt_image_processor.dart';
import '../../../../core/ocr/receipt_ocr_engine.dart';
import '../../../../core/ocr/receipt_parser.dart';
import '../models/expense_note_model.dart';

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

  String? _lastCompressedPath;
  String? get lastCompressedPath => _lastCompressedPath;

  /// Memfoto nota dari [controller] kamera, memprosesnya (crop ke bingkai
  /// pemandu + grayscale/contrast enhancement - lihat
  /// ReceiptImageProcessor.enhanceForOcr), lalu menjalankan OCR + parsing.
  ///
  /// SEBELUM perbaikan ini, langkah di sini HANYA re-kompresi JPEG murni
  /// (target ~300KB) tanpa enhancement piksel apa pun, dan bingkai
  /// pemandu di layar kamera murni dekoratif - foto PENUH (termasuk
  /// latar belakang di luar bingkai) selalu dikirim mentah-mentah ke ML
  /// Kit. Itu penyebab utama hasil scan "kurang teliti/rinci" yang
  /// dilaporkan user - nota kertas thermal yang pudar dibaca OCR dalam
  /// kontras rendah aslinya, dan noise latar belakang ikut terbaca.
  Future<ParsedReceiptResult> captureAndScan(
    CameraController controller,
  ) async {
    if (!controller.value.isInitialized) {
      throw CameraException('NOT_INITIALIZED', 'Kamera belum siap digunakan.');
    }

    final rawFile = await controller.takePicture();
    final processed = await ReceiptImageProcessor.enhanceForOcr(
      sourcePath: rawFile.path,
      receiptId: _uuid.v4(),
      cropToGuideFrame: true,
    );

    final recognizedText = await _ocrEngine.recognizeText(processed.processedPath);
    final parsed = _parser.parse(recognizedText);

    _lastCompressedPath = processed.processedPath;

    final rawFileOnDisk = File(rawFile.path);
    if (await rawFileOnDisk.exists()) {
      await rawFileOnDisk.delete();
    }

    return parsed;
  }

  /// Menjalankan OCR langsung pada berkas gambar yang ada (misal dari
  /// Galeri) - TIDAK crop ke bingkai pemandu (foto galeri belum tentu
  /// mengikuti proporsi bingkai kamera; crop paksa berisiko memotong
  /// nota itu sendiri), tapi tetap dapat grayscale/contrast enhancement.
  Future<ParsedReceiptResult> scanImageFile(String imagePath) async {
    final processed = await ReceiptImageProcessor.enhanceForOcr(
      sourcePath: imagePath,
      receiptId: _uuid.v4(),
      cropToGuideFrame: false,
    );
    final recognizedText = await _ocrEngine.recognizeText(processed.processedPath);
    final parsed = _parser.parse(recognizedText);
    _lastCompressedPath = processed.processedPath;
    return parsed;
  }

  /// Cek apakah hash SHA-256 berkas fisik identik sudah tersimpan sebelumnya
  Future<String?> findDuplicateByHash(String sha256Hash) async {
    if (sha256Hash.isEmpty) return null;
    final rows = await _database.query(
      'expense_notes',
      where: 'originalSha256 = ? OR processedSha256 = ?',
      whereArgs: [sha256Hash, sha256Hash],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['id'] as String;
    }
    return null;
  }

  /// Deteksi duplikat: kombinasi vendor + tanggal + nominal
  Future<String?> findDuplicateNoteId({
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    String? excludeId,
  }) async {
    final signature = _buildDuplicateSignature(
      vendorName: vendorName,
      transactionDate: transactionDate,
      totalAmount: totalAmount,
    );

    final rows = await _database.query('expense_notes');
    for (final row in rows) {
      final existing = ExpenseNoteModel.fromMap(row);
      if (excludeId != null && existing.id == excludeId) continue;

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
    await _database.insert(
      'expense_notes',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return model;
  }

  Future<ExpenseNoteModel> update(ExpenseNoteModel model) async {
    await _database.update(
      'expense_notes',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
    return model;
  }

  Future<void> delete(String id) async {
    await _database.delete(
      'expense_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _database.delete(
      'sync_queue',
      where: 'entityLocalId = ?',
      whereArgs: [id],
    );
  }

  Future<ExpenseNoteModel?> getNoteById(String id) async {
    final rows = await _database.query(
      'expense_notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExpenseNoteModel.fromMap(rows.first);
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
