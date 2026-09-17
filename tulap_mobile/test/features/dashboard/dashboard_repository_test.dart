import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:tulap_mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:tulap_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:tulap_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/action_required_entity.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/dashboard_period.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/dashboard_summary_entity.dart';

class _FakeLocalDataSource implements DashboardLocalDataSource {
  final DashboardSummaryEntity summary;
  _FakeLocalDataSource(this.summary);

  @override
  Future<DashboardSummaryEntity> getDashboardAnalytics(DashboardPeriod period) async {
    return summary;
  }
}

class _FakeRemoteDataSource implements DashboardRemoteDataSource {
  final DashboardSummaryModel? summary;
  final bool shouldFail;
  _FakeRemoteDataSource({this.summary, this.shouldFail = false});

  @override
  Future<DashboardSummaryModel> getDashboardAnalytics(DashboardPeriod period) async {
    if (shouldFail) throw Exception('Server error');
    return summary!;
  }
}

class _FakeNetworkInfo implements NetworkInfo {
  final bool connected;
  final _controller = StreamController<bool>.broadcast();
  _FakeNetworkInfo(this.connected);

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
}

void main() {
  final period = DashboardPeriod.thisMonth(now: DateTime(2026, 8, 15));

  final localSummary = DashboardSummaryEntity(
    period: period,
    activityTotal: 24,
    activityCompleted: 18,
    activityOngoing: 6,
    activityCompletionRate: 75.0,
    photoCount: 104,
    videoCount: 22,
    evidenceTotal: 126,
    travelTotal: 8,
    travelDays: 14,
    expenseTotal: 8750000,
    lpjComplete: 6,
    lpjIncomplete: 2,
    actionRequired: const [
      ActionRequiredEntity(
        type: ActionRequiredType.lpjIncomplete,
        title: '2 LPJ belum lengkap',
        subtitle: 'Lengkapi dokumen',
        count: 2,
      ),
      ActionRequiredEntity(
        type: ActionRequiredType.pendingSync,
        title: '5 bukti belum tersinkronisasi',
        subtitle: 'Periksa koneksi',
        count: 5,
      ),
    ],
    isOfflineDerived: true,
  );

  final remoteModel = DashboardSummaryModel(
    period: period,
    activityTotal: 24,
    activityCompleted: 18,
    activityOngoing: 6,
    activityCompletionRate: 75.0,
    photoCount: 104,
    videoCount: 22,
    evidenceTotal: 126,
    travelTotal: 8,
    travelDays: 14,
    expenseTotal: 8750000,
    lpjComplete: 6,
    lpjIncomplete: 2,
    actionRequired: const [
      ActionRequiredEntity(
        type: ActionRequiredType.lpjIncomplete,
        title: '2 LPJ belum lengkap',
        subtitle: 'Lengkapi dokumen',
        count: 2,
      ),
    ],
    isOfflineDerived: false,
  );

  group('DashboardRepositoryImpl Tests', () {
    test('returns local analytics when offline without remote call', () async {
      final repo = DashboardRepositoryImpl(
        localDataSource: _FakeLocalDataSource(localSummary),
        remoteDataSource: _FakeRemoteDataSource(shouldFail: true),
        networkInfo: _FakeNetworkInfo(false),
      );

      final result = await repo.getDashboardAnalytics(period: period);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (data) {
          expect(data.activityTotal, 24);
          expect(data.activityCompleted, 18);
          expect(data.evidenceTotal, 126);
          expect(data.expenseTotal, 8750000);
          expect(data.isOfflineDerived, true);
        },
      );
    });

    test('merges local pending sync items into remote data when online', () async {
      final repo = DashboardRepositoryImpl(
        localDataSource: _FakeLocalDataSource(localSummary),
        remoteDataSource: _FakeRemoteDataSource(summary: remoteModel),
        networkInfo: _FakeNetworkInfo(true),
      );

      final result = await repo.getDashboardAnalytics(period: period);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (data) {
          expect(data.activityTotal, 24);
          expect(data.isOfflineDerived, false);
          // Action required contains both remote incomplete LPJ and local pendingSync
          expect(data.actionRequired.length, 2);
          expect(data.actionRequired.any((a) => a.type == ActionRequiredType.pendingSync), true);
        },
      );
    });

    test('falls back gracefully to local analytics when remote throws error', () async {
      final repo = DashboardRepositoryImpl(
        localDataSource: _FakeLocalDataSource(localSummary),
        remoteDataSource: _FakeRemoteDataSource(shouldFail: true),
        networkInfo: _FakeNetworkInfo(true),
      );

      final result = await repo.getDashboardAnalytics(period: period);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (data) {
          expect(data.activityTotal, 24);
          expect(data.isOfflineDerived, true);
        },
      );
    });
  });
}
