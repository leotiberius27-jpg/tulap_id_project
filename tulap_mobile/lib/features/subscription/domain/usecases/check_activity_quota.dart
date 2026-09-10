import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_code.dart';
import '../entities/subscription_entity.dart';
import '../entities/subscription_usage_entity.dart';
import '../repositories/subscription_repository.dart';

/// CheckActivityQuota
/// ----------------------------------------------------------------------
/// Dipakai SEBELUM membuka layar "Buat Kegiatan" (Bagian 30 dokumen
/// redesign). HANYA menahan pembuatan kegiatan baru - tidak pernah
/// dipakai untuk membatasi akses ke kegiatan yang sudah ada, foto,
/// checklist, sinkronisasi, atau LPJ.
/// ----------------------------------------------------------------------
class CheckActivityQuota {
  final SubscriptionRepository _repository;

  CheckActivityQuota(this._repository);

  Future<Either<Failure, SubscriptionUsageEntity>> call() async {
    final subscriptionResult = await _repository.getCurrentSubscription();

    if (subscriptionResult is Left<Failure, SubscriptionEntity?>) {
      return Left(subscriptionResult.value);
    }

    final subscription =
        (subscriptionResult as Right<Failure, SubscriptionEntity?>).value;
    final planCode = subscription?.planCode ?? PlanCode.gratis;
    return _repository.getUsage(planCode);
  }
}
