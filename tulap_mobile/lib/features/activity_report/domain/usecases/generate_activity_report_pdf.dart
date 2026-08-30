import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_report_entity.dart';
import '../entities/report_draft_data.dart';
import '../repositories/activity_report_repository.dart';

class GenerateActivityReportPdf {
  final ActivityReportRepository _repository;
  const GenerateActivityReportPdf(this._repository);

  Future<Either<Failure, ActivityReportEntity>> call({
    required ReportDraftData draft,
  }) {
    return _repository.generatePdfReport(draft: draft);
  }
}
