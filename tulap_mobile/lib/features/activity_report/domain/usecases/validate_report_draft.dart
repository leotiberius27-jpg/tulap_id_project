import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/report_draft_data.dart';
import '../entities/report_validation_result.dart';
import '../repositories/activity_report_repository.dart';

class ValidateReportDraft {
  final ActivityReportRepository _repository;
  const ValidateReportDraft(this._repository);

  Future<Either<Failure, ReportValidationResult>> call({
    required ReportDraftData draft,
  }) {
    return _repository.validateReportDraft(draft: draft);
  }
}
