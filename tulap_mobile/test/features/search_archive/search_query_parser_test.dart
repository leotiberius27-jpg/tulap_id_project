import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/search_archive/data/services/search_query_parser.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_result_entity.dart';

void main() {
  late SearchQueryParser parser;

  setUp(() {
    parser = SearchQueryParser();
  });

  group('SearchQueryParser Tests', () {
    test('should parse exact Activity ID', () {
      final res = parser.parse('ACT-20260828-001');
      expect(res.isExactId, isTrue);
      expect(res.exactId, 'ACT-20260828-001');
      expect(res.detectedType, SearchEntityType.activity);
    });

    test('should parse exact Travel Mission ID', () {
      final res = parser.parse('PD-20260828-1001');
      expect(res.isExactId, isTrue);
      expect(res.exactId, 'PD-20260828-1001');
      expect(res.detectedType, SearchEntityType.travel);
    });

    test('should parse exact LPJ Package ID', () {
      final res = parser.parse('LPJ-20260828-9999');
      expect(res.isExactId, isTrue);
      expect(res.exactId, 'LPJ-20260828-9999');
      expect(res.detectedType, SearchEntityType.lpj);
    });

    test('should normalize Indonesian currency and amounts', () {
      final res1 = parser.parse('Rp450.000');
      expect(res1.detectedAmount, 450000.0);

      final res2 = parser.parse('Rp 1.500.000');
      expect(res2.detectedAmount, 1500000.0);

      final res3 = parser.parse('nota 50000');
      expect(res3.detectedAmount, 50000.0);
      expect(res3.detectedType, SearchEntityType.receipt);
    });

    test('should detect Indonesian month and year from natural language query', () {
      final res = parser.parse('monitoring kendaraan di Mimika Agustus 2026');
      expect(res.detectedMonth, 8);
      expect(res.detectedYear, 2026);
      expect(res.detectedType, SearchEntityType.activity);
    });

    test('should detect Indonesian DD/MM/YYYY date format', () {
      final res = parser.parse('kegiatan 26/08/2026');
      expect(res.detectedDate, DateTime(2026, 8, 26));
      expect(res.detectedType, SearchEntityType.activity);
    });
  });
}
