import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_period.dart';
import '../entities/dashboard_summary_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardAnalytics {
  final DashboardRepository repository;

  GetDashboardAnalytics(this.repository);

  Future<Either<Failure, DashboardSummaryEntity>> call({
    required DashboardPeriod period,
    bool forceOffline = false,
  }) {
    return repository.getDashboardAnalytics(
      period: period,
      forceOffline: forceOffline,
    );
  }
}
