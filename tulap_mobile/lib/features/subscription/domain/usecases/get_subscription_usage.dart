import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_code.dart';
import '../entities/subscription_usage_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionUsage {
  final SubscriptionRepository _repository;

  GetSubscriptionUsage(this._repository);

  Future<Either<Failure, SubscriptionUsageEntity>> call(PlanCode planCode) =>
      _repository.getUsage(planCode);
}
