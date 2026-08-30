import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../entities/report_draft_data.dart';
import '../repositories/activity_report_repository.dart';

class AssembleReportDraft {
  final ActivityReportRepository _repository;
  const AssembleReportDraft(this._repository);

  Future<Either<Failure, ReportDraftData>> call({
    required TaskEntity task,
  }) {
    return _repository.assembleReportDraft(task: task);
  }
}
