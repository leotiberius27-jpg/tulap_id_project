import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/activity_report_repository.dart';

class VerifyReportSha256 {
  final ActivityReportRepository _repository;
  const VerifyReportSha256(this._repository);

  Future<Either<Failure, bool>> call({
    required String reportId,
    required String localPdfPath,
  }) {
    return _repository.verifyReportSha256(
      reportId: reportId,
      localPdfPath: localPdfPath,
    );
  }
}
