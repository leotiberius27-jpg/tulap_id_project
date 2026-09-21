import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
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

  const ProcessedReceiptImageResult({
    required this.originalPath,
    required this.processedPath,
    required this.originalSha256,
    required this.processedSha256,
    required this.enhanceMode,
  });
}

/// ReceiptImageProcessor
/// ----------------------------------------------------------------------
/// Sebelum perbaikan ini, jalur nyata pemindaian nota (lihat
/// ExpenseOcrLocalDataSource._compressImage - SEBELUM diperbaiki) hanya
/// melakukan re-kompresi JPEG murni (target ~300KB, tanpa EXIF) sebelum
/// dikirim ke ML Kit - kelas ini ("enhancement" sungguhan: grayscale,
/// contrast stretch, crop ke bingkai pemandu) sudah ditulis tapi TIDAK
/// PERNAH dipanggil dari jalur produksi. Akibatnya bingkai pemandu di
/// layar kamera murni dekoratif (foto penuh tetap dikirim apa adanya,
/// termasuk latar belakang meja/tangan) dan nota kertas thermal yang
/// pudar/kurang kontras (kondisi paling umum di lapangan) tetap dibaca
/// OCR dalam kondisi kontras rendah aslinya - persis penyebab keluhan
/// "OCR kurang teliti, ada informasi yang bertolak belakang".
///
/// `enhanceForOcr()` di bawah ini sekarang BENAR-BENAR dipanggil oleh
/// ExpenseOcrLocalDataSource, menggantikan _compressImage lama.
/// ----------------------------------------------------------------------
class ReceiptImageProcessor {
  /// Sisi terpanjang maksimum sesudah diproses - cukup tinggi agar ML Kit
  /// tetap bisa membaca font kecil nota thermal, tapi tidak sebesar foto
  /// mentah sensor kamera (bisa >4000px) yang bikin proses piksel lambat
  /// dan file besar tanpa manfaat akurasi tambahan.
  static const int _maxDimension = 1920;

  /// Fraksi area tengah gambar yang dipertahankan saat `cropToGuideFrame`
  /// aktif - HARUS SAMA PERSIS dengan bingkai pemandu di layar
  /// (ReceiptScannerPage._DocumentScanOverlay: 85% lebar x 58% tinggi,
  /// tengah) supaya apa yang dilihat user di layar adalah benar-benar
  /// yang dibaca OCR, bukan cuma dekorasi.
  static const double _cropWidthFraction = 0.85;
  static const double _cropHeightFraction = 0.58;

  /// enhanceForOcr
  /// ----------------------------------------------------------------------
  /// Pipeline nyata (piksel diproses, BUKAN sekadar re-kompresi JPEG):
  ///   1. Bake EXIF orientation - mencegah OCR membaca foto potret dari
  ///      sensor kamera dalam keadaan miring/menyamping.
  ///   2. (Opsional, HANYA untuk hasil jepretan kamera langsung -
  ///      `cropToGuideFrame: true`) Crop ke area bingkai pemandu, buang
  ///      latar belakang di luar nota. TIDAK dipakai untuk impor Galeri
  ///      karena foto galeri belum tentu mengikuti proporsi bingkai yang
  ///      sama - crop paksa berisiko memotong nota itu sendiri.
  ///   3. Downscale ke `_maxDimension` bila perlu.
  ///   4. Grayscale + normalize (contrast stretch otomatis berdasarkan
  ///      rentang piksel aktual) - kunci perbaikan akurasi untuk nota
  ///      kertas thermal yang pudar/kurang kontras.
  ///   5. Mode Hitam Putih menambah binarisasi (threshold) untuk nota
  ///      yang sangat pudar atau difoto dengan pencahayaan buruk/backlit.
  /// ----------------------------------------------------------------------
  static Future<ProcessedReceiptImageResult> enhanceForOcr({
    required String sourcePath,
    required String receiptId,
    ReceiptEnhanceMode enhanceMode = ReceiptEnhanceMode.document,
    bool cropToGuideFrame = false,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Berkas nota sumber tidak ditemukan: $sourcePath');
    }
    final originalBytes = await sourceFile.readAsBytes();

    final appDocDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDocDir.path, 'tulap_receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final originalDestPath = p.join(receiptsDir.path, '${receiptId}_orig.jpg');
    await File(originalDestPath).writeAsBytes(originalBytes);
    final originalSha256 = sha256.convert(originalBytes).toString();

    final processedDestPath = p.join(receiptsDir.path, '${receiptId}_proc.jpg');
    final decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      // Format gagal di-decode (jarang) - pakai berkas asli apa adanya
      // daripada gagal total, supaya alur scan tetap bisa lanjut ke OCR.
      await File(processedDestPath).writeAsBytes(originalBytes);
      return ProcessedReceiptImageResult(
        originalPath: originalDestPath,
        processedPath: processedDestPath,
        originalSha256: originalSha256,
        processedSha256: originalSha256,
        enhanceMode: enhanceMode,
      );
    }

    var working = img.bakeOrientation(decoded);

    if (cropToGuideFrame) {
      final cropWidth = (working.width * _cropWidthFraction).round();
      final cropHeight = (working.height * _cropHeightFraction).round();
      final x = ((working.width - cropWidth) / 2).round();
      final y = ((working.height - cropHeight) / 2).round();
      working = img.copyCrop(
        working,
        x: x.clamp(0, working.width - 1),
        y: y.clamp(0, working.height - 1),
        width: cropWidth.clamp(1, working.width),
        height: cropHeight.clamp(1, working.height),
      );
    }

    if (working.width > _maxDimension || working.height > _maxDimension) {
      working = working.width >= working.height
          ? img.copyResize(working, width: _maxDimension)
          : img.copyResize(working, height: _maxDimension);
    }

    switch (enhanceMode) {
      case ReceiptEnhanceMode.original:
        break;
      case ReceiptEnhanceMode.document:
        working = img.normalize(img.grayscale(working), min: 0, max: 255);
        break;
      case ReceiptEnhanceMode.blackAndWhite:
        working = _binarize(img.normalize(img.grayscale(working), min: 0, max: 255));
        break;
    }

    final encodedBytes = img.encodeJpg(working, quality: 92);
    await File(processedDestPath).writeAsBytes(encodedBytes);
    final processedSha256 = sha256.convert(encodedBytes).toString();

    return ProcessedReceiptImageResult(
      originalPath: originalDestPath,
      processedPath: processedDestPath,
      originalSha256: originalSha256,
      processedSha256: processedSha256,
      enhanceMode: enhanceMode,
    );
  }

  /// Binarisasi berbasis ambang rata-rata luminansi (pendekatan sederhana
  /// dari Otsu tanpa histogram penuh) - cukup untuk memisahkan tinta
  /// gelap dari kertas terang pada nota thermal yang sangat pudar.
  /// Ambang digeser sedikit di bawah rata-rata (`* 0.92`) agar goresan
  /// tinta tipis tidak ikut hilang jadi putih.
  static img.Image _binarize(img.Image grayscale) {
    num sum = 0;
    for (final pixel in grayscale) {
      sum += pixel.r;
    }
    final pixelCount = grayscale.width * grayscale.height;
    final threshold = pixelCount == 0 ? 128 : (sum / pixelCount) * 0.92;

    final out = img.Image.from(grayscale);
    for (final pixel in out) {
      final value = pixel.r >= threshold ? 255 : 0;
      pixel
        ..r = value
        ..g = value
        ..b = value;
    }
    return out;
  }

  /// Menghitung SHA-256 secara langsung dari file
  static Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
