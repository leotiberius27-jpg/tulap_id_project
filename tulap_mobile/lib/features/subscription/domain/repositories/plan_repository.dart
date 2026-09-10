import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_entity.dart';

/// PlanRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class PlanRepository {
  /// Daftar seluruh paket Tulap secara berurutan (Gratis, Basic, Pro,
  /// Pro+) - sumber tunggal untuk carousel maupun comparison sheet.
  Future<Either<Failure, List<PlanEntity>>> getPlans();
}
