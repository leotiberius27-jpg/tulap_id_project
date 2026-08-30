import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard_period.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource localDataSource;
  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardAnalytics({
    required DashboardPeriod period,
    bool forceOffline = false,
  }) async {
    try {
      final isOnline = !forceOffline && await networkInfo.isConnected;

      if (!isOnline) {
        final localResult = await localDataSource.getDashboardAnalytics(period);
        return Right(localResult);
      }

      try {
        final remoteResult = await remoteDataSource.getDashboardAnalytics(period);

        // Fetch local pending sync items to ensure device outbox state is included in Action Required
        final localSummary = await localDataSource.getDashboardAnalytics(period);
        final pendingSyncActions = localSummary.actionRequired
            .where((a) => a.type.name == 'pendingSync')
            .toList();

        final mergedActions = [
          ...remoteResult.actionRequired.where((a) => a.type.name != 'pendingSync'),
          ...pendingSyncActions,
        ];

        final mergedSummary = DashboardSummaryEntity(
          period: remoteResult.period,
          activityTotal: remoteResult.activityTotal > 0
              ? remoteResult.activityTotal
              : localSummary.activityTotal,
          activityCompleted: remoteResult.activityCompleted > 0
              ? remoteResult.activityCompleted
              : localSummary.activityCompleted,
          activityOngoing: remoteResult.activityOngoing > 0
              ? remoteResult.activityOngoing
              : localSummary.activityOngoing,
          activityCompletionRate: remoteResult.activityCompletionRate > 0
              ? remoteResult.activityCompletionRate
              : localSummary.activityCompletionRate,
          photoCount: remoteResult.photoCount > 0
              ? remoteResult.photoCount
              : localSummary.photoCount,
          videoCount: remoteResult.videoCount,
          evidenceTotal: remoteResult.evidenceTotal > 0
              ? remoteResult.evidenceTotal
              : localSummary.evidenceTotal,
          travelTotal: remoteResult.travelTotal > 0
              ? remoteResult.travelTotal
              : localSummary.travelTotal,
          travelCompleted: remoteResult.travelCompleted > 0
              ? remoteResult.travelCompleted
              : localSummary.travelCompleted,
          travelDays: remoteResult.travelDays > 0
              ? remoteResult.travelDays
              : localSummary.travelDays,
          expenseTotal: remoteResult.expenseTotal > 0
              ? remoteResult.expenseTotal
              : localSummary.expenseTotal,
          expensePreviousPeriodTotal: remoteResult.expensePreviousPeriodTotal,
          reportCount: remoteResult.reportCount > 0
              ? remoteResult.reportCount
              : localSummary.reportCount,
          lpjComplete: remoteResult.lpjComplete > 0
              ? remoteResult.lpjComplete
              : localSummary.lpjComplete,
          lpjIncomplete: remoteResult.lpjIncomplete > 0
              ? remoteResult.lpjIncomplete
              : localSummary.lpjIncomplete,
          actionRequired: mergedActions.isNotEmpty
              ? mergedActions
              : localSummary.actionRequired,
          activityTrend: remoteResult.activityTrend.isNotEmpty
              ? remoteResult.activityTrend
              : localSummary.activityTrend,
          expenseByCategory: remoteResult.expenseByCategory.isNotEmpty
              ? remoteResult.expenseByCategory
              : localSummary.expenseByCategory,
          topLocations: remoteResult.topLocations.isNotEmpty
              ? remoteResult.topLocations
              : localSummary.topLocations,
          travelDestinations: remoteResult.travelDestinations.isNotEmpty
              ? remoteResult.travelDestinations
              : localSummary.travelDestinations,
          insights: remoteResult.insights.isNotEmpty
              ? remoteResult.insights
              : localSummary.insights,
          isOfflineDerived: false,
        );

        return Right(mergedSummary);
      } catch (remoteError) {
        // Transparent fallback to local database on remote error
        final localResult = await localDataSource.getDashboardAnalytics(period);
        return Right(localResult);
      }
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
