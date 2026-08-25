import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ParsedReceiptField
/// ----------------------------------------------------------------------
/// Satu field hasil parsing beserta confidence score-nya (0.0 - 1.0).
/// Field dengan confidence rendah ditandai di UI Review Sheet agar user
/// memeriksa manual sebelum simpan (Bagian 13 & 20 spesifikasi).
/// ----------------------------------------------------------------------
class ParsedReceiptField<T> {
  final T? value;
  final double confidence;

  const ParsedReceiptField({required this.value, required this.confidence});

  bool get needsReview => confidence < 0.6 || value == null;
}

enum ReceiptCategory {
  bbm,
  tol,
  penginapan,
  retail,
  konsumsi,
  transportasiLain,
  lainnya,
}

class ParsedReceiptResult {
  final ParsedReceiptField<String> vendorName;
  final ParsedReceiptField<DateTime> transactionDate;
  final ParsedReceiptField<double> totalAmount;
  final ParsedReceiptField<double> taxAmount;
  final ParsedReceiptField<String> receiptNumber;
  final ReceiptCategory category;
  final String rawText;

  const ParsedReceiptResult({
    required this.vendorName,
    required this.transactionDate,
    required this.totalAmount,
    required this.taxAmount,
    required this.receiptNumber,
    required this.category,
    required this.rawText,
  });
}

/// ReceiptParser
/// ----------------------------------------------------------------------
/// Inti dari "OCR Receipt Scanner Retail Lokal" (Bagian 2.1 dokumen
/// requirement awal & Bagian 9 spesifikasi produk). Mengubah teks
/// mentah hasil ML Kit menjadi field terstruktur, dengan kamus istilah
/// yang mengenali format nota retail Indonesia (SPBU, tol, Indomaret/
/// Alfamart, hotel).
///
/// PENDEKATAN: rule-based dengan regex + kamus vendor, BUKAN model ML
/// custom - dipilih karena (a) tidak butuh training data, (b) mudah
/// di-maintain & ditambah vendor baru oleh developer non-ML, dan
/// (c) berjalan sepenuhnya on-device tanpa biaya API OCR eksternal.
/// Kekurangannya: kurang robust untuk format nota yang sangat tidak
/// standar - inilah kenapa Review Sheet & confidence indicator WAJIB
/// ada, bukan opsional.
/// ----------------------------------------------------------------------
class ReceiptParser {
  /// Kamus vendor retail lokal yang dikenali & kategorinya - mudah
  /// ditambah tanpa mengubah logic parsing.
  static const Map<String, ReceiptCategory> _knownVendorKeywords = {
    'PERTAMINA': ReceiptCategory.bbm,
    'SHELL': ReceiptCategory.bbm,
    'SPBU': ReceiptCategory.bbm,
    'JASA MARGA': ReceiptCategory.tol,
    'TOL': ReceiptCategory.tol,
    'INDOMARET': ReceiptCategory.retail,
    'ALFAMART': ReceiptCategory.retail,
    'ALFAMIDI': ReceiptCategory.retail,
    'HOTEL': ReceiptCategory.penginapan,
    'GRAND': ReceiptCategory.penginapan, // Grand Hotel X, dsb
    'SYARIAH HOTEL': ReceiptCategory.penginapan,
    'RESTO': ReceiptCategory.konsumsi,
    'RESTORAN': ReceiptCategory.konsumsi,
    'WARUNG': ReceiptCategory.konsumsi,
    'RUMAH MAKAN': ReceiptCategory.konsumsi,
    'GRAB': ReceiptCategory.transportasiLain,
    'GOJEK': ReceiptCategory.transportasiLain,
    'PARKIR': ReceiptCategory.transportasiLain,
  };

  /// Kata kunci baris nominal total - urutan prioritas dari yang paling
  /// spesifik. Nota Indonesia sering memakai istilah berbeda-beda.
  static const List<String> _totalKeywords = [
    'TOTAL BAYAR',
    'GRAND TOTAL',
    'TOTAL HARGA',
    'JUMLAH BAYAR',
    'TOTAL',
    'JUMLAH',
  ];

  static const List<String> _taxKeywords = ['PPN', 'PAJAK', 'TAX'];

  ParsedReceiptResult parse(RecognizedText recognizedText) {
    final rawText = recognizedText.text;
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final vendor = _extractVendor(lines);
    final category = _inferCategory(rawText, vendor.value);
    final total = _extractAmount(lines, _totalKeywords, isTotal: true);
    final tax = _extractAmount(lines, _taxKeywords, isTotal: false);
    final date = _extractDate(rawText);
    final receiptNumber = _extractReceiptNumber(lines);

    return ParsedReceiptResult(
      vendorName: vendor,
      transactionDate: date,
      totalAmount: total,
      taxAmount: tax,
      receiptNumber: receiptNumber,
      category: category,
      rawText: rawText,
    );
  }

  /// Nama vendor pada nota thermal umumnya berada di 1-3 baris teratas,
  /// biasanya dalam huruf kapital semua dan ukuran font terbesar pada
  /// nota. Heuristik: ambil baris pertama yang cukup panjang (>3 char)
  /// dan tidak berupa angka/tanggal murni.
  ParsedReceiptField<String> _extractVendor(List<String> lines) {
    for (final line in lines.take(5)) {
      final isMostlyLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      final isNotJustNumbers = !RegExp(r'^[\d\s\-/:.,]+$').hasMatch(line);
      if (line.length > 3 && isMostlyLetters && isNotJustNumbers) {
        return ParsedReceiptField(value: line, confidence: 0.75);
      }
    }
    return const ParsedReceiptField(value: null, confidence: 0.0);
  }

  ReceiptCategory _inferCategory(String rawText, String? vendorName) {
    final upperText = rawText.toUpperCase();
    for (final entry in _knownVendorKeywords.entries) {
      if (upperText.contains(entry.key)) {
        return entry.value;
      }
    }
    return ReceiptCategory.lainnya;
  }

  /// Mencari baris yang mengandung salah satu [keywords], lalu
  /// mengekstrak angka nominal dari baris tersebut (menangani format
  /// "Rp 150.000", "150,000", "150000", dsb - umum di nota Indonesia
  /// yang tidak konsisten memakai titik/koma sebagai pemisah ribuan).
  ParsedReceiptField<double> _extractAmount(
    List<String> lines,
    List<String> keywords, {
    required bool isTotal,
  }) {
    for (final keyword in keywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _parseIndonesianCurrency(line);
          if (amount != null) {
            // Baris dengan keyword paling spesifik ("TOTAL BAYAR") diberi
            // confidence lebih tinggi daripada keyword generik ("TOTAL").
            final confidence = keyword.split(' ').length > 1 ? 0.85 : 0.65;
            return ParsedReceiptField(value: amount, confidence: confidence);
          }
        }
      }
    }
    return ParsedReceiptField(value: null, confidence: 0.0);
  }

  double? _parseIndonesianCurrency(String line) {
    // Ambil semua kemunculan angka dengan pemisah ribuan/desimal,
    // lalu pilih yang terpanjang (biasanya itu nominalnya, bukan
    // nomor telepon/kode struk yang kebetulan ikut ter-capture).
    final matches = RegExp(r'[\d.,]{4,}').allMatches(line).toList();
    if (matches.isEmpty) return null;

    final rawNumber = matches
        .map((m) => m.group(0)!)
        .reduce((a, b) => a.length >= b.length ? a : b);

    // Normalisasi: hapus separator ribuan (titik), ganti koma desimal
    // jadi titik. Asumsi format Indonesia: 150.000,50 -> 150000.50
    final normalized = rawNumber.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  ParsedReceiptField<DateTime> _extractDate(String rawText) {
    // Pola umum: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD-MM-YY
    final pattern = RegExp(r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})');
    final match = pattern.firstMatch(rawText);

    if (match == null) {
      return const ParsedReceiptField(value: null, confidence: 0.0);
    }

    try {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000; // Format 2 digit, mis. "24" -> 2024

      final date = DateTime(year, month, day);
      // Validasi sederhana: tanggal tidak boleh di masa depan jauh atau
      // tahun yang tidak masuk akal.
      final isPlausible =
          date.isBefore(DateTime.now().add(const Duration(days: 1))) &&
          year >= 2020;

      return ParsedReceiptField(
        value: date,
        confidence: isPlausible ? 0.8 : 0.3,
      );
    } catch (_) {
      return const ParsedReceiptField(value: null, confidence: 0.0);
    }
  }

  ParsedReceiptField<String> _extractReceiptNumber(List<String> lines) {
    final pattern = RegExp(
      r'(NO\.?\s?(NOTA|STRUK|INVOICE|REF)?\s?[:.]?\s?)([A-Z0-9\-\/]{4,})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return ParsedReceiptField(value: match.group(3), confidence: 0.7);
      }
    }
    return const ParsedReceiptField(value: null, confidence: 0.0);
  }
}
