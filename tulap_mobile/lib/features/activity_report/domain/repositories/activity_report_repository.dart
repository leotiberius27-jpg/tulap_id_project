import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../entities/activity_report_entity.dart';
import '../entities/report_draft_data.dart';
import '../entities/report_validation_result.dart';

abstract class ActivityReportRepository {
  /// Mengumpulkan data terstruktur aktivitas menjadi Draf Laporan (Auto-Draft)
  Future<Either<Failure, ReportDraftData>> assembleReportDraft({
    required TaskEntity task,
  });

  /// Memvalidasi kelayakan draf laporan sebelum ekspor PDF
  Future<Either<Failure, ReportValidationResult>> validateReportDraft({
    required ReportDraftData draft,
  });

  /// Mengompilasi dan mengenerate file PDF A4 laporan resmi, menghitung SHA-256,
  /// menyimpan snapshot ke database lokal, dan mendaftarkan ke outbox sync queue.
  Future<Either<Failure, ActivityReportEntity>> generatePdfReport({
    required ReportDraftData draft,
  });

  /// Mengambil daftar riwayat laporan untuk satu tugas kegiatan
  Future<Either<Failure, List<ActivityReportEntity>>> getReportsByTaskId(
    String taskId,
  );

  /// Mengambil detail satu laporan berdasarkan ID
  Future<Either<Failure, ActivityReportEntity>> getReportById(
    String reportId,
  );

  /// Menghapus / mengarsipkan laporan
  Future<Either<Failure, void>> deleteReport({
    required String reportId,
    required String taskId,
  });

  /// Memverifikasi integritas SHA-256 file PDF lokal terhadap nilai tercatat
  Future<Either<Failure, bool>> verifyReportSha256({
    required String reportId,
    required String localPdfPath,
  });
}
