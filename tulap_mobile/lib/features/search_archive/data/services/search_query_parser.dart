import '../../domain/entities/search_result_entity.dart';
import '../../domain/entities/search_query_parsed.dart';

class SearchQueryParser {
  static const Map<String, int> _indonesianMonths = {
    'januari': 1,
    'jan': 1,
    'februari': 2,
    'feb': 2,
    'maret': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'mei': 5,
    'juni': 6,
    'jun': 6,
    'juli': 7,
    'jul': 7,
    'agustus': 8,
    'agt': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'oktober': 10,
    'okt': 10,
    'november': 11,
    'nov': 11,
    'desember': 12,
    'des': 12,
  };

  static final RegExp _exactIdRegex = RegExp(
    r'^(ACT|PD|EV|NTA|EXP|LAP|LPJ|ST|SPPD)[-_/][A-Za-z0-9-_/]+$',
    caseSensitive: false,
  );

  static final RegExp _currencyRegex = RegExp(
    r'(?:rp\.?\s*)?([0-9]{1,3}(?:\.[0-9]{3})+|[0-9]{4,10})',
    caseSensitive: false,
  );

  static final RegExp _yearRegex = RegExp(r'\b(20[2-3][0-9])\b');

  static final RegExp _dateRegex = RegExp(
    r'\b([0-3]?[0-9])[/-]([0-1]?[0-9])[/-](20[2-3][0-9])\b',
  );

  SearchQueryParsed parse(String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) {
      return SearchQueryParsed(
        rawQuery: rawQuery,
        cleanText: '',
      );
    }

    final lower = trimmed.toLowerCase();

    // 1. Exact ID Check
    String? exactId;
    bool isExactId = false;
    SearchEntityType? detectedType;

    if (_exactIdRegex.hasMatch(trimmed)) {
      exactId = trimmed.toUpperCase();
      isExactId = true;
      if (exactId.startsWith('ACT')) {
        detectedType = SearchEntityType.activity;
      } else if (exactId.startsWith('PD') || exactId.startsWith('SPPD')) {
        detectedType = SearchEntityType.travel;
      } else if (exactId.startsWith('EV')) {
        detectedType = SearchEntityType.evidence;
      } else if (exactId.startsWith('NTA') || exactId.startsWith('EXP')) {
        detectedType = SearchEntityType.receipt;
      } else if (exactId.startsWith('LAP')) {
        detectedType = SearchEntityType.report;
      } else if (exactId.startsWith('LPJ')) {
        detectedType = SearchEntityType.lpj;
      }
    }

    // 2. Amount / Currency Normalization
    double? detectedAmount;
    final currencyMatch = _currencyRegex.firstMatch(trimmed);
    if (currencyMatch != null && currencyMatch.group(1) != null) {
      final rawDigits = currencyMatch.group(1)!.replaceAll('.', '');
      final val = double.tryParse(rawDigits);
      if (val != null && val >= 1000) {
        detectedAmount = val;
      }
    }

    // 3. Year Detection
    int? detectedYear;
    final yearMatch = _yearRegex.firstMatch(trimmed);
    if (yearMatch != null) {
      detectedYear = int.tryParse(yearMatch.group(1)!);
    }

    // 4. Month Detection
    int? detectedMonth;
    for (final entry in _indonesianMonths.entries) {
      final monthRegex = RegExp('\\b${entry.key}\\b', caseSensitive: false);
      if (monthRegex.hasMatch(lower)) {
        detectedMonth = entry.value;
        break;
      }
    }

    // 5. Full Date Pattern (DD/MM/YYYY)
    DateTime? detectedDate;
    final dateMatch = _dateRegex.firstMatch(trimmed);
    if (dateMatch != null) {
      final day = int.tryParse(dateMatch.group(1)!);
      final month = int.tryParse(dateMatch.group(2)!);
      final year = int.tryParse(dateMatch.group(3)!);
      if (day != null && month != null && year != null) {
        try {
          detectedDate = DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // 6. Entity Type Keywords in natural language query
    if (detectedType == null) {
      if (lower.contains('kegiatan') || lower.contains('monitoring') || lower.contains('inspeksi')) {
        detectedType = SearchEntityType.activity;
      } else if (lower.contains('perjalanan') || lower.contains('sppd') || lower.contains('dinas')) {
        detectedType = SearchEntityType.travel;
      } else if (lower.contains('foto') || lower.contains('video') || lower.contains('dokumentasi')) {
        detectedType = SearchEntityType.evidence;
      } else if (lower.contains('nota') || lower.contains('kuitansi') || lower.contains('bbm') || lower.contains('struk')) {
        detectedType = SearchEntityType.receipt;
      } else if (lower.contains('laporan') || lower.contains('berita acara')) {
        detectedType = SearchEntityType.report;
      } else if (lower.contains('surat tugas') || lower.contains('dokumen') || lower.contains('visum')) {
        detectedType = SearchEntityType.document;
      } else if (lower.contains('lpj')) {
        detectedType = SearchEntityType.lpj;
      }
    }

    // Clean text for text search
    final cleanText = trimmed
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    return SearchQueryParsed(
      rawQuery: rawQuery,
      cleanText: cleanText,
      exactId: exactId,
      detectedType: detectedType,
      detectedDate: detectedDate,
      detectedYear: detectedYear,
      detectedMonth: detectedMonth,
      detectedAmount: detectedAmount,
      isExactId: isExactId,
    );
  }
}
