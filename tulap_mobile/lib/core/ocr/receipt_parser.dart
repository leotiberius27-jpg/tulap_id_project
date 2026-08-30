import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ParsedReceiptField
/// ----------------------------------------------------------------------
/// Satu field hasil parsing beserta confidence score-nya (0.0 - 1.0).
/// Field dengan confidence rendah ditandai di UI Review Sheet agar user
/// memeriksa manual sebelum simpan (Bagian 13, 33, 34).
/// ----------------------------------------------------------------------
class ParsedReceiptField<T> {
  final T? value;
  final double confidence;

  const ParsedReceiptField({required this.value, required this.confidence});

  bool get needsReview => confidence < 0.7 || value == null;
}

enum ReceiptCategory {
  bbm('BBM'),
  tol('Tol'),
  penginapan('Penginapan'),
  retail('Retail'),
  konsumsi('Konsumsi'),
  transportasiLain('Transportasi'),
  atk('ATK / Fotokopi'),
  perlengkapan('Perlengkapan'),
  lainnya('Lainnya');

  final String label;
  const ReceiptCategory(this.label);
}

enum ReceiptPaymentMethod {
  tunai('Tunai / Cash'),
  qris('QRIS'),
  kartu('Kartu Debit / Kredit'),
  transfer('Transfer Bank'),
  lainnya('Lainnya');

  final String label;
  const ReceiptPaymentMethod(this.label);
}

class ParsedReceiptResult {
  final ParsedReceiptField<String> vendorName;
  final ParsedReceiptField<DateTime> transactionDate;
  final ParsedReceiptField<String> transactionTime;
  final ParsedReceiptField<double> totalAmount;
  final ParsedReceiptField<double> subtotal;
  final ParsedReceiptField<double> taxAmount;
  final ParsedReceiptField<double> discountAmount;
  final ParsedReceiptField<double> serviceCharge;
  final ParsedReceiptField<String> receiptNumber;
  final ReceiptCategory category;
  final ReceiptPaymentMethod paymentMethod;
  final String rawText;

  const ParsedReceiptResult({
    required this.vendorName,
    required this.transactionDate,
    required this.transactionTime,
    required this.totalAmount,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.serviceCharge,
    required this.receiptNumber,
    required this.category,
    required this.paymentMethod,
    required this.rawText,
  });

  double get averageConfidence {
    final scores = [
      vendorName.confidence,
      transactionDate.confidence,
      totalAmount.confidence,
    ];
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

/// ReceiptParser
/// ----------------------------------------------------------------------
/// Parser OCR Berbasis Aturan & Regex yang dioptimalkan untuk Nota Indonesia:
/// - SPBU (Pertamina, Shell, Solar, Pertalite, Pertamax, Dexlite)
/// - Minimarket & Retail (Indomaret, Alfamart, Alfamidi, Superindo, dsb.)
/// - Restoran, Rumah Makan, & Kafe (RM Nusantara, Padang, Solaria, dsb.)
/// - Transportasi & Tol (Jasa Marga, Grab, Gojek, Tiket, Parkir, dsb.)
/// - Hotel, Wisma, & Penginapan
/// - ATK, Percetakan, & Fotokopi
/// ----------------------------------------------------------------------
class ReceiptParser {
  static const Map<String, ReceiptCategory> _knownVendorKeywords = {
    // BBM / SPBU
    'PERTAMINA': ReceiptCategory.bbm,
    'SPBU': ReceiptCategory.bbm,
    'SHELL': ReceiptCategory.bbm,
    'BP AKR': ReceiptCategory.bbm,
    'PERTALITE': ReceiptCategory.bbm,
    'PERTAMAX': ReceiptCategory.bbm,
    'DEXLITE': ReceiptCategory.bbm,
    'SOLAR': ReceiptCategory.bbm,

    // Tol & Transportasi
    'JASA MARGA': ReceiptCategory.tol,
    'CITRA MARGA': ReceiptCategory.tol,
    'GERBANG TOL': ReceiptCategory.tol,
    'TOL': ReceiptCategory.tol,
    'GRAB': ReceiptCategory.transportasiLain,
    'GOJEK': ReceiptCategory.transportasiLain,
    'MAXIM': ReceiptCategory.transportasiLain,
    'DAMRI': ReceiptCategory.transportasiLain,
    'PARKIR': ReceiptCategory.transportasiLain,
    'TIKET': ReceiptCategory.transportasiLain,
    'KERETA': ReceiptCategory.transportasiLain,

    // Retail & Minimarket
    'INDOMARET': ReceiptCategory.retail,
    'ALFAMART': ReceiptCategory.retail,
    'ALFAMIDI': ReceiptCategory.retail,
    'SUPERINDO': ReceiptCategory.retail,
    'HYPERMART': ReceiptCategory.retail,
    'TRANSMART': ReceiptCategory.retail,
    'MINIMARKET': ReceiptCategory.retail,
    'TOKO': ReceiptCategory.retail,

    // Penginapan / Hotel
    'HOTEL': ReceiptCategory.penginapan,
    'GRAND HOTEL': ReceiptCategory.penginapan,
    'HORISON': ReceiptCategory.penginapan,
    'ASTON': ReceiptCategory.penginapan,
    'SANTIKA': ReceiptCategory.penginapan,
    'WISMA': ReceiptCategory.penginapan,
    'GUEST HOUSE': ReceiptCategory.penginapan,
    'RESORT': ReceiptCategory.penginapan,

    // Konsumsi / F&B
    'RESTO': ReceiptCategory.konsumsi,
    'RESTORAN': ReceiptCategory.konsumsi,
    'WARUNG': ReceiptCategory.konsumsi,
    'RUMAH MAKAN': ReceiptCategory.konsumsi,
    'RM ': ReceiptCategory.konsumsi,
    'KAFE': ReceiptCategory.konsumsi,
    'CAFE': ReceiptCategory.konsumsi,
    'SOLARIA': ReceiptCategory.konsumsi,
    'KFC': ReceiptCategory.konsumsi,
    'MCDONALD': ReceiptCategory.konsumsi,
    'DAPUR': ReceiptCategory.konsumsi,
    'BAKSO': ReceiptCategory.konsumsi,
    'MIE': ReceiptCategory.konsumsi,

    // ATK & Percetakan
    'FOTOCOPY': ReceiptCategory.atk,
    'PHOTOCOPY': ReceiptCategory.atk,
    'PERCETAKAN': ReceiptCategory.atk,
    'PRINTING': ReceiptCategory.atk,
    'ATK': ReceiptCategory.atk,
    'TOKO BUKU': ReceiptCategory.atk,
  };

  static const List<String> _totalKeywords = [
    'TOTAL BAYAR',
    'GRAND TOTAL',
    'TOTAL AKHIR',
    'TOTAL HARGA',
    'JUMLAH BAYAR',
    'JUMLAH TOTAL',
    'TAGIHAN',
    'TOTAL',
    'JUMLAH',
  ];

  static const List<String> _subtotalKeywords = [
    'SUBTOTAL',
    'SUB TOTAL',
    'HARGA JUAL',
    'JUMLAH BRUTO',
  ];

  static const List<String> _taxKeywords = [
    'PPN',
    'PAJAK',
    'TAX',
    'PB1',
    'PPN 11%',
    'PPN 10%',
  ];

  static const List<String> _discountKeywords = [
    'DISKON',
    'DISCOUNT',
    'POTONGAN',
    'HEMAT',
  ];

  static const List<String> _serviceKeywords = [
    'SERVICE',
    'BIAYA LAYANAN',
    'SERVICE CHARGE',
  ];

  static const Map<String, int> _indonesianMonths = {
    'JANUARI': 1, 'JAN': 1,
    'FEBRUARI': 2, 'FEB': 2,
    'MARET': 3, 'MAR': 3,
    'APRIL': 4, 'APR': 4,
    'MEI': 5, 'MAY': 5,
    'JUNI': 6, 'JUN': 6,
    'JULI': 7, 'JUL': 7,
    'AGUSTUS': 8, 'AGU': 8, 'AGS': 8,
    'SEPTEMBER': 9, 'SEP': 9,
    'OKTOBER': 10, 'OKT': 10, 'OCT': 10,
    'NOVEMBER': 11, 'NOV': 11,
    'DESEMBER': 12, 'DES': 12, 'DEC': 12,
  };

  ParsedReceiptResult parse(RecognizedText recognizedText) {
    return parseText(recognizedText.text);
  }

  ParsedReceiptResult parseText(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final vendor = _extractVendor(lines, rawText);
    final category = _inferCategory(rawText, vendor.value);
    final total = _extractTotalAmount(lines);
    final subtotal = _extractAmount(lines, _subtotalKeywords);
    final tax = _extractAmount(lines, _taxKeywords);
    final discount = _extractAmount(lines, _discountKeywords);
    final service = _extractAmount(lines, _serviceKeywords);
    final date = _extractDate(rawText);
    final time = _extractTime(rawText);
    final receiptNumber = _extractReceiptNumber(lines);
    final paymentMethod = _extractPaymentMethod(rawText);

    return ParsedReceiptResult(
      vendorName: vendor,
      transactionDate: date,
      transactionTime: time,
      totalAmount: total,
      subtotal: subtotal,
      taxAmount: tax,
      discountAmount: discount,
      serviceCharge: service,
      receiptNumber: receiptNumber,
      category: category,
      paymentMethod: paymentMethod,
      rawText: rawText,
    );
  }

  ParsedReceiptField<String> _extractVendor(List<String> lines, String rawText) {
    // 1. Cek kecocokan kamus vendor terkenal di seluruh baris awal
    final upperText = rawText.toUpperCase();
    for (final key in _knownVendorKeywords.keys) {
      if (upperText.contains(key)) {
        for (final line in lines.take(6)) {
          if (line.toUpperCase().contains(key)) {
            return ParsedReceiptField(value: line, confidence: 0.92);
          }
        }
      }
    }

    // 2. Heuristik baris teratas: ambil baris pertama yang berisi teks nama toko
    for (final line in lines.take(5)) {
      final isMostlyLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      final isNotJustNumbers = !RegExp(r'^[\d\s\-/:.,]+$').hasMatch(line);
      final isNotDate = !RegExp(r'\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}').hasMatch(line);
      if (line.length >= 3 && isMostlyLetters && isNotJustNumbers && isNotDate) {
        return ParsedReceiptField(value: line, confidence: 0.78);
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

  ReceiptPaymentMethod _extractPaymentMethod(String rawText) {
    final upper = rawText.toUpperCase();
    if (upper.contains('QRIS') || upper.contains('GOPAY') || upper.contains('OVO') || upper.contains('SHOPEEPAY') || upper.contains('DANA')) {
      return ReceiptPaymentMethod.qris;
    }
    if (upper.contains('DEBIT') || upper.contains('KREDIT') || upper.contains('BCA') || upper.contains('MANDIRI') || upper.contains('BRI') || upper.contains('BNI') || upper.contains('EDC')) {
      return ReceiptPaymentMethod.kartu;
    }
    if (upper.contains('TRANSFER') || upper.contains('VA ') || upper.contains('VIRTUAL ACCOUNT')) {
      return ReceiptPaymentMethod.transfer;
    }
    if (upper.contains('TUNAI') || upper.contains('CASH') || upper.contains('KEMBALI') || upper.contains('KEMBALIAN')) {
      return ReceiptPaymentMethod.tunai;
    }
    return ReceiptPaymentMethod.tunai;
  }

  /// Ekstraksi khusus Total Amount dengan menolak baris TUNAI / KEMBALIAN
  ParsedReceiptField<double> _extractTotalAmount(List<String> lines) {
    // Cari baris yang mengandung kata kunci total
    for (final keyword in _totalKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final upper = line.toUpperCase();

        // Tolak baris yang jelas-jelas uang kembalian / uang tunai dibayar
        if (upper.contains('KEMBALI') || upper.contains('KEMBALIAN') || upper.contains('CHANGE')) {
          continue;
        }

        if (upper.contains(keyword)) {
          // Cari angka di baris yang sama
          var amount = _parseIndonesianCurrency(line);

          // Jika tidak ada di baris yang sama, periksa 1 baris setelahnya (layout kolom)
          if (amount == null && i + 1 < lines.length) {
            amount = _parseIndonesianCurrency(lines[i + 1]);
          }

          if (amount != null && amount > 0) {
            final confidence = keyword.contains(' ') ? 0.95 : 0.82;
            return ParsedReceiptField(value: amount, confidence: confidence);
          }
        }
      }
    }

    // Fallback: cari nominal angka terbesar yang masuk akal pada 10 baris terbawah
    final candidates = <double>[];
    for (final line in lines.reversed.take(10)) {
      final upper = line.toUpperCase();
      if (upper.contains('KEMBALI') || upper.contains('TUNAI') || upper.contains('CASH')) continue;
      final val = _parseIndonesianCurrency(line);
      if (val != null && val >= 500 && val <= 500000000) {
        candidates.add(val);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a));
      return ParsedReceiptField(value: candidates.first, confidence: 0.55);
    }

    return const ParsedReceiptField(value: null, confidence: 0.0);
  }

  ParsedReceiptField<double> _extractAmount(List<String> lines, List<String> keywords) {
    for (final keyword in keywords) {
      for (final line in lines) {
        if (line.toUpperCase().contains(keyword)) {
          final amount = _parseIndonesianCurrency(line);
          if (amount != null && amount > 0) {
            return ParsedReceiptField(value: amount, confidence: 0.80);
          }
        }
      }
    }
    return const ParsedReceiptField(value: null, confidence: 0.0);
  }

  double? _parseIndonesianCurrency(String line) {
    // Bersihkan karakter prefix Rupiah
    var cleaned = line.replaceAll(RegExp(r'[Rr][Pp]\.?\s?'), '').trim();

    final matches = RegExp(r'[\d.,]{3,}').allMatches(cleaned).toList();
    if (matches.isEmpty) return null;

    // Ambil string angka terpanjang
    final rawNumber = matches
        .map((m) => m.group(0)!)
        .reduce((a, b) => a.length >= b.length ? a : b);

    // Format Indonesia: 125.000 atau 125.000,00 atau 125,000
    // Kasus 1: "125.000,00" atau "1.500.000,50" -> titik pemisah ribuan, koma desimal
    if (rawNumber.contains('.') && rawNumber.contains(',')) {
      final normalized = rawNumber.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    // Kasus 2: "125.000" atau "1.250.000" -> titik sebagai pemisah ribuan (3 digit)
    if (rawNumber.contains('.')) {
      final parts = rawNumber.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        final normalized = rawNumber.replaceAll('.', '');
        return double.tryParse(normalized);
      } else if (parts.length > 1 && parts.last.length == 2) {
        // Desimal 2 digit format titik
        return double.tryParse(rawNumber);
      } else {
        final normalized = rawNumber.replaceAll('.', '');
        return double.tryParse(normalized);
      }
    }

    // Kasus 3: "125,000" -> koma sebagai pemisah ribuan
    if (rawNumber.contains(',')) {
      final parts = rawNumber.split(',');
      if (parts.length > 1 && parts.last.length == 3) {
        final normalized = rawNumber.replaceAll(',', '');
        return double.tryParse(normalized);
      } else if (parts.length > 1 && parts.last.length == 2) {
        final normalized = rawNumber.replaceAll(',', '.');
        return double.tryParse(normalized);
      }
    }

    return double.tryParse(rawNumber);
  }

  ParsedReceiptField<DateTime> _extractDate(String rawText) {
    // 1. Pola numerik: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD-MM-YY, YYYY-MM-DD
    final numericPattern = RegExp(r'(\d{1,4})[\/\-.](\d{1,2})[\/\-.](\d{2,4})');
    final matchNum = numericPattern.firstMatch(rawText);
    if (matchNum != null) {
      try {
        final p1 = int.parse(matchNum.group(1)!);
        final p2 = int.parse(matchNum.group(2)!);
        final p3 = int.parse(matchNum.group(3)!);

        int day, month, year;
        if (p1 > 1000) {
          // Format YYYY-MM-DD
          year = p1;
          month = p2;
          day = p3;
        } else {
          // Format DD/MM/YYYY
          day = p1;
          month = p2;
          year = p3 < 100 ? 2000 + p3 : p3;
        }

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          final date = DateTime(year, month, day);
          return ParsedReceiptField(value: date, confidence: 0.88);
        }
      } catch (_) {}
    }

    // 2. Pola nama bulan Bahasa Indonesia: "26 Agu 2026", "15 Agustus 2026"
    final textPattern = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})',
      caseSensitive: false,
    );
    final matchText = textPattern.firstMatch(rawText);
    if (matchText != null) {
      try {
        final day = int.parse(matchText.group(1)!);
        final monthStr = matchText.group(2)!.toUpperCase();
        var year = int.parse(matchText.group(3)!);
        if (year < 100) year += 2000;

        final month = _indonesianMonths[monthStr];
        if (month != null && day >= 1 && day <= 31) {
          return ParsedReceiptField(
            value: DateTime(year, month, day),
            confidence: 0.95,
          );
        }
      } catch (_) {}
    }

    return const ParsedReceiptField(value: null, confidence: 0.0);
  }

  ParsedReceiptField<String> _extractTime(String rawText) {
    final pattern = RegExp(r'(\d{1,2})[:.](\d{2})(:(\d{2}))?');
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!) ?? 0;
      final minute = int.tryParse(match.group(2)!) ?? 0;
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        final formatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        return ParsedReceiptField(value: formatted, confidence: 0.85);
      }
    }
    return const ParsedReceiptField(value: null, confidence: 0.0);
  }

  ParsedReceiptField<String> _extractReceiptNumber(List<String> lines) {
    final pattern = RegExp(
      r'(NO\.?\s?(NOTA|STRUK|INVOICE|REF|TRANS|TX|RESI)?\s?[:.]?\s?)([A-Z0-9\-\/]{3,})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return ParsedReceiptField(value: match.group(3), confidence: 0.80);
      }
    }
    return const ParsedReceiptField(value: null, confidence: 0.0);
  }
}
