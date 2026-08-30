import 'action_required_entity.dart';
import 'activity_trend_point.dart';
import 'dashboard_period.dart';
import 'expense_category_stat.dart';
import 'top_location_stat.dart';
import 'travel_destination_stat.dart';

class DashboardSummaryEntity {
  final DashboardPeriod period;

  // 1. Activity Analytics
  final int activityTotal;
  final int activityCompleted;
  final int activityOngoing;
  final double activityCompletionRate;

  // 2. Evidence Analytics
  final int photoCount;
  final int videoCount;
  final int evidenceTotal;

  // 3. Travel & SPPD Analytics
  final int travelTotal;
  final int travelCompleted;
  final int travelDays;

  // 4. Expense Intelligence
  final double expenseTotal;
  final double? expensePreviousPeriodTotal;

  // 5. Reports & LPJ Completeness
  final int reportCount;
  final int lpjComplete;
  final int lpjIncomplete;

  // 6. Actionable Lists & Trends
  final List<ActionRequiredEntity> actionRequired;
  final List<ActivityTrendPoint> activityTrend;
  final List<ExpenseCategoryStat> expenseByCategory;
  final List<TopLocationStat> topLocations;
  final List<TravelDestinationStat> travelDestinations;
  final List<String> insights;

  // 7. Data source origin
  final bool isOfflineDerived;

  const DashboardSummaryEntity({
    required this.period,
    this.activityTotal = 0,
    this.activityCompleted = 0,
    this.activityOngoing = 0,
    this.activityCompletionRate = 0.0,
    this.photoCount = 0,
    this.videoCount = 0,
    this.evidenceTotal = 0,
    this.travelTotal = 0,
    this.travelCompleted = 0,
    this.travelDays = 0,
    this.expenseTotal = 0.0,
    this.expensePreviousPeriodTotal,
    this.reportCount = 0,
    this.lpjComplete = 0,
    this.lpjIncomplete = 0,
    this.actionRequired = const [],
    this.activityTrend = const [],
    this.expenseByCategory = const [],
    this.topLocations = const [],
    this.travelDestinations = const [],
    this.insights = const [],
    this.isOfflineDerived = false,
  });

  /// Factory for clean empty state
  factory DashboardSummaryEntity.empty(DashboardPeriod period) {
    return DashboardSummaryEntity(period: period);
  }
}
