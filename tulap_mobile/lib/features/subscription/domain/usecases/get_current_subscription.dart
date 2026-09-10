import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetCurrentSubscription {
  final SubscriptionRepository _repository;

  GetCurrentSubscription(this._repository);

  Future<Either<Failure, SubscriptionEntity?>> call() =>
      _repository.getCurrentSubscription();
}
