import '../../domain/entities/action_required_entity.dart';
import '../../domain/entities/activity_trend_point.dart';
import '../../domain/entities/dashboard_period.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/expense_category_stat.dart';
import '../../domain/entities/top_location_stat.dart';
import '../../domain/entities/travel_destination_stat.dart';

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.period,
    super.activityTotal,
    super.activityCompleted,
    super.activityOngoing,
    super.activityCompletionRate,
    super.photoCount,
    super.videoCount,
    super.evidenceTotal,
    super.travelTotal,
    super.travelCompleted,
    super.travelDays,
    super.expenseTotal,
    super.expensePreviousPeriodTotal,
    super.reportCount,
    super.lpjComplete,
    super.lpjIncomplete,
    super.actionRequired,
    super.activityTrend,
    super.expenseByCategory,
    super.topLocations,
    super.travelDestinations,
    super.insights,
    super.isOfflineDerived,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json, DashboardPeriod period) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};

    // 1. Action Required List
    final actionRequiredRaw = json['actionRequired'] as List<dynamic>? ?? [];
    final actionRequired = actionRequiredRaw.map((a) {
      final item = a as Map<String, dynamic>;
      final typeStr = item['type'] as String? ?? 'activityIncomplete';
      final sevStr = item['severity'] as String? ?? 'warning';

      ActionRequiredType type;
      switch (typeStr) {
        case 'lpjIncomplete':
          type = ActionRequiredType.lpjIncomplete;
          break;
        case 'pendingSync':
          type = ActionRequiredType.pendingSync;
          break;
        case 'receiptNeedsReview':
          type = ActionRequiredType.receiptNeedsReview;
          break;
        case 'integrityIssue':
          type = ActionRequiredType.integrityIssue;
          break;
        case 'activityIncomplete':
        default:
          type = ActionRequiredType.activityIncomplete;
          break;
      }

      ActionRequiredSeverity severity;
      switch (sevStr) {
        case 'danger':
          severity = ActionRequiredSeverity.danger;
          break;
        case 'info':
          severity = ActionRequiredSeverity.info;
          break;
        case 'warning':
        default:
          severity = ActionRequiredSeverity.warning;
          break;
      }

      return ActionRequiredEntity(
        type: type,
        title: item['title'] as String? ?? '',
        subtitle: item['subtitle'] as String? ?? '',
        count: (item['count'] as num?)?.toInt() ?? 0,
        severity: severity,
        filterParams: item['filterParams'] as Map<String, dynamic>?,
      );
    }).toList();

    // 2. Activity Trend List
    final trendRaw = json['activityTrend'] as List<dynamic>? ?? [];
    final activityTrend = trendRaw.map((t) {
      final item = t as Map<String, dynamic>;
      return ActivityTrendPoint(
        date: item['date'] as String? ?? '',
        label: item['label'] as String? ?? '',
        count: (item['count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    // 3. Expense By Category List
    final expenseRaw = json['expenseByCategory'] as List<dynamic>? ?? [];
    final expenseByCategory = expenseRaw.map((e) {
      final item = e as Map<String, dynamic>;
      return ExpenseCategoryStat(
        category: item['category'] as String? ?? 'Lainnya',
        amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
        percentage: (item['percentage'] as num?)?.toDouble() ?? 0.0,
        count: (item['count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    // 4. Top Locations List
    final locRaw = json['topLocations'] as List<dynamic>? ?? [];
    LocationActivityStat parseActivity(Map<String, dynamic> a) {
      final rawDate = a['date'] as String?;
      return LocationActivityStat(
        taskId: a['taskId'] as String? ?? '',
        title: a['title'] as String? ?? '',
        status: a['status'] as String? ?? '',
        date: rawDate != null ? DateTime.tryParse(rawDate) : null,
      );
    }

    final topLocations = locRaw.map((l) {
      final item = l as Map<String, dynamic>;
      final activitiesRaw = item['activities'] as List<dynamic>? ?? [];
      final activities = activitiesRaw
          .map((a) => parseActivity(a as Map<String, dynamic>))
          .toList();
      final latestActivityRaw = item['latestActivity'] as Map<String, dynamic>?;
      return TopLocationStat(
        location: item['location'] as String? ?? '',
        count: (item['count'] as num?)?.toInt() ?? 0,
        latitude: (item['latitude'] as num?)?.toDouble(),
        longitude: (item['longitude'] as num?)?.toDouble(),
        thumbnailUrl: item['thumbnailUrl'] as String?,
        latestActivity:
            latestActivityRaw != null ? parseActivity(latestActivityRaw) : null,
        activities: activities,
      );
    }).toList();

    // 5. Travel Destinations List
    final destRaw = json['travelDestinations'] as List<dynamic>? ?? [];
    final travelDestinations = destRaw.map((d) {
      final item = d as Map<String, dynamic>;
      return TravelDestinationStat(
        destination: item['destination'] as String? ?? '',
        count: (item['count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    // 6. Insights
    final insightsRaw = json['insights'] as List<dynamic>? ?? [];
    final insights = insightsRaw.map((i) => i.toString()).toList();

    return DashboardSummaryModel(
      period: period,
      activityTotal: (summaryJson['activityTotal'] as num?)?.toInt() ?? 0,
      activityCompleted: (summaryJson['activityCompleted'] as num?)?.toInt() ?? 0,
      activityOngoing: (summaryJson['activityOngoing'] as num?)?.toInt() ?? 0,
      activityCompletionRate: (summaryJson['activityCompletionRate'] as num?)?.toDouble() ?? 0.0,
      photoCount: (summaryJson['photoCount'] as num?)?.toInt() ?? 0,
      videoCount: (summaryJson['videoCount'] as num?)?.toInt() ?? 0,
      evidenceTotal: (summaryJson['evidenceTotal'] as num?)?.toInt() ?? 0,
      travelTotal: (summaryJson['travelTotal'] as num?)?.toInt() ?? 0,
      travelCompleted: (summaryJson['travelCompleted'] as num?)?.toInt() ?? 0,
      travelDays: (summaryJson['travelDays'] as num?)?.toInt() ?? 0,
      expenseTotal: (summaryJson['expenseTotal'] as num?)?.toDouble() ?? 0.0,
      expensePreviousPeriodTotal: (summaryJson['expensePreviousPeriodTotal'] as num?)?.toDouble(),
      reportCount: (summaryJson['reportCount'] as num?)?.toInt() ?? 0,
      lpjComplete: (summaryJson['lpjComplete'] as num?)?.toInt() ?? 0,
      lpjIncomplete: (summaryJson['lpjIncomplete'] as num?)?.toInt() ?? 0,
      actionRequired: actionRequired,
      activityTrend: activityTrend,
      expenseByCategory: expenseByCategory,
      topLocations: topLocations,
      travelDestinations: travelDestinations,
      insights: insights,
      isOfflineDerived: false,
    );
  }
}
