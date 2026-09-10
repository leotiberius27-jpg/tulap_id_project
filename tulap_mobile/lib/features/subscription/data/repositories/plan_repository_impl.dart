import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/plan_repository.dart';
import '../plan_config.dart';

class PlanRepositoryImpl implements PlanRepository {
  @override
  Future<Either<Failure, List<PlanEntity>>> getPlans() async {
    return Right(PlanConfig.plans);
  }
}
