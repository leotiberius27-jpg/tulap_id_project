import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

/// SelectPlan
/// ----------------------------------------------------------------------
/// HANYA untuk memilih paket GRATIS - lihat
/// SubscriptionRepository.selectFreePlan(). Paket berbayar TIDAK lagi
/// lewat use case ini (Bagian 41 instruksi payment) - lihat
/// CreateCheckout + CheckoutController.
/// ----------------------------------------------------------------------
class SelectPlan {
  final SubscriptionRepository _repository;

  SelectPlan(this._repository);

  Future<Either<Failure, SubscriptionEntity>> call() {
    return _repository.selectFreePlan();
  }
}
