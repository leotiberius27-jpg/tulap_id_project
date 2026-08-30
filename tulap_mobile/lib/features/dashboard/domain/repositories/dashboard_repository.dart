import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_period.dart';
import '../entities/dashboard_summary_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardAnalytics({
    required DashboardPeriod period,
    bool forceOffline = false,
  });
}
