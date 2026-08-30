import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/activity_report_repository.dart';

class DeleteActivityReport {
  final ActivityReportRepository _repository;
  const DeleteActivityReport(this._repository);

  Future<Either<Failure, void>> call({
    required String reportId,
    required String taskId,
  }) {
    return _repository.deleteReport(reportId: reportId, taskId: taskId);
  }
}
