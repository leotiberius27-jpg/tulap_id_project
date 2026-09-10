import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../task_detail/domain/repositories/task_repository.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_code.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_owner_type.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/entities/subscription_usage_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/payments_remote_datasource.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../datasources/subscription_local_datasource.dart';

/// SubscriptionRepositoryImpl
/// ----------------------------------------------------------------------
/// Backend (GET /subscriptions/me) adalah SUMBER KEBENARAN status
/// langganan & kuota (Bagian 24 & 38 instruksi payment - backend yang
/// menegakkan, "Paket Saya harus langsung berubah" setelah pembayaran
/// terverifikasi). SubscriptionLocalDataSource dipertahankan HANYA
/// sebagai cache offline - dipakai saat request ke backend gagal (mis.
/// tidak ada koneksi), BUKAN sumber kebenaran utama lagi.
/// ----------------------------------------------------------------------
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionLocalDataSource _localDataSource;
  final TaskRepository _taskRepository;
  final AuthSessionManager _authSessionManager;

  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required SubscriptionLocalDataSource localDataSource,
    required TaskRepository taskRepository,
    required AuthSessionManager authSessionManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _taskRepository = taskRepository,
       _authSessionManager = authSessionManager;

  SubscriptionUsageEntity? _lastRemoteUsage;

  SubscriptionEntity _mapSubscription(Map<String, dynamic> json, String ownerId) {
    return SubscriptionEntity(
      id: json['id'] as String,
      ownerType: SubscriptionOwnerType.personal,
      ownerId: ownerId,
      planCode: PlanCode.fromApiValue(json['planCode'] as String),
      billingCycle: BillingCycle.fromApiValue(json['billingCycle'] as String),
      status: SubscriptionStatus.fromApiValue(json['status'] as String),
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
    );
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> getCurrentSubscription() async {
    final ownerId = _authSessionManager.currentUser?.id ?? 'local_user';
    try {
      final view = await _remoteDataSource.getMySubscription();
      final subscription = _mapSubscription(
        view['subscription'] as Map<String, dynamic>,
        ownerId,
      );
      final usage = view['usage'] as Map<String, dynamic>;
      _lastRemoteUsage = SubscriptionUsageEntity(
        used: usage['used'] as int,
        limit: usage['limit'] as int,
        periodEnd: DateTime.parse(usage['periodEnd'] as String),
      );
      await _localDataSource.saveSubscription(subscription);
      return Right(subscription);
    } catch (e) {
      // Offline fallback (Bagian 29 instruksi payment - kegagalan jaringan
      // BUKAN berarti gagal, tampilkan cache terakhir yang diketahui).
      final cached = await _localDataSource.getSubscription();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(extractApiErrorMessage(e, 'Gagal memuat status langganan.')));
    }
  }

  @override
  Future<Either<Failure, SubscriptionUsageEntity>> getUsage(PlanCode planCode) async {
    if (_lastRemoteUsage != null) {
      final usage = _lastRemoteUsage!;
      _lastRemoteUsage = null; // sekali pakai - hindari data basi di panggilan berikutnya.
      return Right(usage);
    }

    // Fallback offline: hitung dari kegiatan lokal, sama seperti perilaku
    // lama - fail-open, jangan sampai gangguan jaringan menahan pekerjaan
    // lapangan (lihat activity_quota_guard.dart).
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 1);
    final limit = _activityLimitFor(planCode);

    final tasksResult = await _taskRepository.getActiveTasks();
    return tasksResult.fold((failure) => Left(failure), (tasks) {
      final usedThisMonth = tasks.where((task) {
        final createdAt = task.createdAt ?? task.startDate;
        return !createdAt.isBefore(periodStart) && createdAt.isBefore(periodEnd);
      }).length;

      return Right(
        SubscriptionUsageEntity(used: usedThisMonth, limit: limit, periodEnd: periodEnd),
      );
    });
  }

  int _activityLimitFor(PlanCode planCode) => switch (planCode) {
    PlanCode.gratis => 3,
    PlanCode.basic => 10,
    PlanCode.pro => 30,
    PlanCode.proPlus => 100,
  };

  @override
  Future<Either<Failure, SubscriptionEntity>> selectFreePlan() async {
    final ownerId = _authSessionManager.currentUser?.id ?? 'local_user';
    try {
      final json = await _remoteDataSource.selectFreePlan();
      final subscription = _mapSubscription(json, ownerId);
      await _localDataSource.saveSubscription(subscription);
      return Right(subscription);
    } catch (e) {
      return Left(ServerFailure(extractApiErrorMessage(e, 'Gagal memperbarui paket.')));
    }
  }
}
