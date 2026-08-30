import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/dashboard/data/services/dashboard_insight_engine.dart';

void main() {
  group('DashboardInsightEngine Tests', () {
    const engine = DashboardInsightEngine();

    test('generates factual, traceable insights based on operational data', () {
      final insights = engine.generateInsights(
        activityTotal: 24,
        activityCompleted: 18,
        expenseTotal: 8750000,
        topExpenseCategory: 'Transportasi',
        topLocation: 'Mimika',
        lpjIncomplete: 2,
        pendingSyncCount: 5,
      );

      expect(insights.length, 5);
      expect(insights[0], contains('18 dari 24 kegiatan'));
      expect(insights[1], contains('Mimika'));
      expect(insights[2], contains('Transportasi'));
      expect(insights[3], contains('2 berkas LPJ'));
      expect(insights[4], contains('5 data bukti tersimpan'));
    });

    test('generates all completed message when completion rate is 100%', () {
      final insights = engine.generateInsights(
        activityTotal: 10,
        activityCompleted: 10,
        expenseTotal: 0,
        lpjIncomplete: 0,
        pendingSyncCount: 0,
      );

      expect(insights.length, 1);
      expect(insights[0], contains('Seluruh 10 kegiatan lapangan'));
    });
  });
}
