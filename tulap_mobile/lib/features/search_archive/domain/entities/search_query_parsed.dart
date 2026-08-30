import 'search_result_entity.dart';

class SearchQueryParsed {
  final String rawQuery;
  final String cleanText;
  final String? exactId;
  final SearchEntityType? detectedType;
  final String? detectedLocation;
  final DateTime? detectedDate;
  final int? detectedYear;
  final int? detectedMonth;
  final double? detectedAmount;
  final bool isExactId;

  const SearchQueryParsed({
    required this.rawQuery,
    required this.cleanText,
    this.exactId,
    this.detectedType,
    this.detectedLocation,
    this.detectedDate,
    this.detectedYear,
    this.detectedMonth,
    this.detectedAmount,
    this.isExactId = false,
  });
}
