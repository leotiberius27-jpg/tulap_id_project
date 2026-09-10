import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_entity.dart';
import '../repositories/plan_repository.dart';

class GetPlans {
  final PlanRepository _repository;

  GetPlans(this._repository);

  Future<Either<Failure, List<PlanEntity>>> call() => _repository.getPlans();
}
