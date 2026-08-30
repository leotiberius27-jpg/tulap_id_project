import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_report_entity.dart';
import '../repositories/activity_report_repository.dart';

class GetTaskReports {
  final ActivityReportRepository _repository;
  const GetTaskReports(this._repository);

  Future<Either<Failure, List<ActivityReportEntity>>> call(String taskId) {
    return _repository.getReportsByTaskId(taskId);
  }
}
