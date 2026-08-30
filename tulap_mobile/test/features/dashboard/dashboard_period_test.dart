import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/dashboard_period.dart';

void main() {
  group('DashboardPeriod Entity Tests', () {
    test('thisMonth generates start of month to end of month', () {
      final ref = DateTime(2026, 8, 15);
      final period = DashboardPeriod.thisMonth(now: ref);

      expect(period.type, DashboardPeriodType.thisMonth);
      expect(period.startDate.year, 2026);
      expect(period.startDate.month, 8);
      expect(period.startDate.day, 1);

      expect(period.endDate.year, 2026);
      expect(period.endDate.month, 8);
      expect(period.endDate.day, 31);
      expect(period.label, 'Agustus 2026');
    });

    test('today generates start and end of day', () {
      final ref = DateTime(2026, 8, 29, 14, 30);
      final period = DashboardPeriod.today(now: ref);

      expect(period.type, DashboardPeriodType.today);
      expect(period.startDate.day, 29);
      expect(period.startDate.hour, 0);
      expect(period.endDate.day, 29);
      expect(period.endDate.hour, 23);
      expect(period.label, 'Hari Ini');
    });

    test('sevenDays generates past 7 days', () {
      final ref = DateTime(2026, 8, 29);
      final period = DashboardPeriod.sevenDays(now: ref);

      expect(period.type, DashboardPeriodType.sevenDays);
      expect(period.startDate.day, 23);
      expect(period.endDate.day, 29);
      expect(period.endDate.hour, 23);
      expect(period.label, '7 Hari Terakhir');
    });

    test('custom period preserves custom range and label', () {
      final start = DateTime(2026, 8, 10);
      final end = DateTime(2026, 8, 20);
      final period = DashboardPeriod.custom(start: start, end: end, label: '10 - 20 Agu');

      expect(period.type, DashboardPeriodType.custom);
      expect(period.startDate.day, 10);
      expect(period.endDate.day, 20);
      expect(period.endDate.hour, 23);
      expect(period.label, '10 - 20 Agu');
    });
  });
}
