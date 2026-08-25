import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/utils/app_date_formatter.dart';

void main() {
  group('AppDateFormatter Tests', () {
    test('formatFull formats date in full Indonesian month', () {
      final date = DateTime(2026, 8, 25);
      expect(AppDateFormatter.formatFull(date), '25 Agustus 2026');
    });

    test('formatCompact formats date with abbreviated month', () {
      final date = DateTime(2026, 8, 25);
      expect(AppDateFormatter.formatCompact(date), '25 Agu 2026');
    });

    test('formatTime formats HH:mm with zero padding', () {
      final time = DateTime(2026, 8, 25, 9, 5);
      expect(AppDateFormatter.formatTime(time), '09:05');
    });

    test('formatDateTime formats date and time together', () {
      final dt = DateTime(2026, 8, 25, 14, 30);
      expect(AppDateFormatter.formatDateTime(dt), '25 Agu 2026 • 14:30');
    });

    test('formatDateRange for same day with zero time', () {
      final start = DateTime(2026, 8, 25);
      final end = DateTime(2026, 8, 25);
      expect(AppDateFormatter.formatDateRange(start, end), '25 Agu 2026');
    });

    test('formatDateRange for same day with specific time', () {
      final start = DateTime(2026, 8, 25, 8, 0);
      final end = DateTime(2026, 8, 25, 17, 0);
      expect(
        AppDateFormatter.formatDateRange(start, end, showTimeIfSameDay: true),
        '25 Agu 2026 • 08:00',
      );
    });

    test('formatDateRange for multi-day in same month', () {
      final start = DateTime(2026, 8, 25);
      final end = DateTime(2026, 8, 28);
      expect(AppDateFormatter.formatDateRange(start, end), '25–28 Agu 2026');
    });

    test('formatDateRange for cross-month in same year', () {
      final start = DateTime(2026, 8, 30);
      final end = DateTime(2026, 9, 2);
      expect(AppDateFormatter.formatDateRange(start, end), '30 Agu – 2 Sep 2026');
    });

    test('formatDateRange for cross-year', () {
      final start = DateTime(2026, 12, 30);
      final end = DateTime(2027, 1, 2);
      expect(AppDateFormatter.formatDateRange(start, end), '30 Des 2026 – 2 Jan 2027');
    });

    test('formatRupiah formats numeric currency properly', () {
      expect(AppDateFormatter.formatRupiah(0), 'Rp0');
      expect(AppDateFormatter.formatRupiah(250000), 'Rp250.000');
      expect(AppDateFormatter.formatRupiah(1500000), 'Rp1.500.000');
    });
  });
}
