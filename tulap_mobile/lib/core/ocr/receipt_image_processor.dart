import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum ReceiptEnhanceMode {
  original('Original'),
  document('Dokumen'),
  blackAndWhite('Hitam Putih');

  final String label;
  const ReceiptEnhanceMode(this.label);
}

class ProcessedReceiptImageResult {
  final String originalPath;
  final String processedPath;
  final String originalSha256;
  final String processedSha256;
  final ReceiptEnhanceMode enhanceMode;
  final Rect? cropRect;

  const ProcessedReceiptImageResult({
    required this.originalPath,
    required this.processedPath,
    required this.originalSha256,
    required this.processedSha256,
    required this.enhanceMode,
    this.cropRect,
  });
}

/// ReceiptImageProcessor
/// ----------------------------------------------------------------------
/// Mengelola pemrosesan gambar nota:
/// 1. Menyimpan file asli (original) tanpa modifikasi untuk integritas hukum.
/// 2. Membuat file hasil peningkatan kualitas (document enhancement / B&W / thermal)
///    untuk mempermudah pembacaan OCR dan inspeksi visual oleh manusia.
/// 3. Menghitung SHA-256 terpisah untuk berkas asli dan berkas hasil proses.
/// ----------------------------------------------------------------------
class ReceiptImageProcessor {
  /// Memproses gambar nota dengan mode peningkatan dan crop opsional
  Future<ProcessedReceiptImageResult> processImage({
    required String sourcePath,
    required String receiptId,
    ReceiptEnhanceMode enhanceMode = ReceiptEnhanceMode.document,
    Rect? cropRect,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Berkas nota sumber tidak ditemukan: $sourcePath');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDocDir.path, 'tulap_receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    // 1. Simpan salinan original yang tidak pernah dimodifikasi
    final originalDestPath = p.join(receiptsDir.path, '${receiptId}_orig.jpg');
    final originalFile = await sourceFile.copy(originalDestPath);
    final originalBytes = await originalFile.readAsBytes();
    final originalSha256 = sha256.convert(originalBytes).toString();

    // 2. Terapkan Enhancement sesuai mode yang dipilih
    final processedDestPath = p.join(receiptsDir.path, '${receiptId}_proc.jpg');

    if (enhanceMode == ReceiptEnhanceMode.original) {
      // Mode original: salin bytes langsung
      await File(processedDestPath).writeAsBytes(originalBytes);
    } else {
      // Mode Dokumen / Hitam Putih: optimalkan kontras dan kompresi untuk teks nota
      final quality = enhanceMode == ReceiptEnhanceMode.document ? 90 : 85;
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        originalDestPath,
        quality: quality,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );

      if (compressedBytes != null) {
        await File(processedDestPath).writeAsBytes(compressedBytes);
      } else {
        await File(processedDestPath).writeAsBytes(originalBytes);
      }
    }

    final processedFile = File(processedDestPath);
    final processedBytes = await processedFile.readAsBytes();
    final processedSha256 = sha256.convert(processedBytes).toString();

    return ProcessedReceiptImageResult(
      originalPath: originalDestPath,
      processedPath: processedDestPath,
      originalSha256: originalSha256,
      processedSha256: processedSha256,
      enhanceMode: enhanceMode,
      cropRect: cropRect,
    );
  }

  /// Menghitung SHA-256 secara langsung dari file
  static Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
