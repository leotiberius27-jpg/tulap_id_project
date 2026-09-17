import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../sync_queue/data/datasources/sync_local_datasource.dart';
import '../../../sync_queue/domain/entities/sync_record_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/data/datasources/timeline_local_datasource.dart';
import '../../../task_detail/data/models/timeline_event_model.dart';
import '../../../task_detail/domain/entities/timeline_event_entity.dart';
import '../../domain/entities/activity_report_entity.dart';
import '../../domain/entities/report_draft_data.dart';
import '../../domain/entities/report_validation_result.dart';
import '../../domain/repositories/activity_report_repository.dart';
import '../datasources/activity_report_local_datasource.dart';
import '../datasources/activity_report_remote_datasource.dart';
import '../services/pdf_report_generator.dart';
import '../services/report_data_assembler.dart';
import '../services/report_validator.dart';

class ReportGenerationFailure extends Failure {
  const ReportGenerationFailure([
    super.message = 'Gagal membuat dokumen laporan. Pastikan ruang penyimpanan cukup.',
  ]);
}

class ActivityReportRepositoryImpl implements ActivityReportRepository {
  final ActivityReportLocalDataSource _localDataSource;
  final ActivityReportRemoteDataSource _remoteDataSource;
  final ReportDataAssembler _assembler;
  final ReportValidator _validator;
  final PdfReportGenerator _pdfGenerator;
  final SyncLocalDataSource? _syncLocalDataSource;
  final TimelineLocalDataSource? _timelineLocalDataSource;
  final Uuid _uuid = const Uuid();

  ActivityReportRepositoryImpl({
    required ActivityReportLocalDataSource localDataSource,
    required ActivityReportRemoteDataSource remoteDataSource,
    required ReportDataAssembler assembler,
    required ReportValidator validator,
    required PdfReportGenerator pdfGenerator,
    SyncLocalDataSource? syncLocalDataSource,
    TimelineLocalDataSource? timelineLocalDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _assembler = assembler,
        _validator = validator,
        _pdfGenerator = pdfGenerator,
        _syncLocalDataSource = syncLocalDataSource,
        _timelineLocalDataSource = timelineLocalDataSource;

  @override
  Future<Either<Failure, ReportDraftData>> assembleReportDraft({
    required TaskEntity task,
  }) async {
    try {
      final draft = await _assembler.assemble(task);
      return Right(draft);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, ReportValidationResult>> validateReportDraft({
    required ReportDraftData draft,
  }) async {
    try {
      final result = _validator.validate(draft);
      return Right(result);
    } catch (_) {
      return const Left(ValidationFailure());
    }
  }

  @override
  Future<Either<Failure, ActivityReportEntity>> generatePdfReport({
    required ReportDraftData draft,
  }) async {
    try {
      final nextVersion = await _localDataSource.getNextVersionNumber(draft.task.id);
      final reportId = _uuid.v4();
      final dateCode = DateFormat('yyyyMMdd').format(DateTime.now());
      final shortId = reportId.substring(0, 6).toUpperCase();
      final reportCode = 'LAP-$dateCode-$shortId';

      // 1. Generate actual PDF & calculate SHA-256
      final reportModel = await _pdfGenerator.generateReportPdf(
        draft: draft,
        reportId: reportId,
        reportCode: reportCode,
        versionNumber: nextVersion,
      );

      // 2. Persist to local database
      final saved = await _localDataSource.insertReport(reportModel);

      // 3. Enqueue to outbox sync queue
      if (_syncLocalDataSource != null) {
        try {
          await _syncLocalDataSource.insertRecord(
            entityType: SyncEntityType.activityReport,
            entityLocalId: saved.id,
            taskId: draft.task.id,
          );
        } catch (_) {}
      }

      // 4. Record to activity timeline
      if (_timelineLocalDataSource != null) {
        try {
          await _timelineLocalDataSource.saveEvent(
            TimelineEventModel(
              id: _uuid.v4(),
              taskId: draft.task.id,
              eventType: TimelineEventType.activityCompleted,
              title: 'Laporan ${saved.formattedVersion} Diterbitkan',
              description: 'Kode: ${saved.reportCode} • ${saved.evidenceCount} Foto • Realisasi: Rp ${saved.totalExpense.toStringAsFixed(0)}',
              eventTimestamp: DateTime.now(),
              metadata: {
                'reportId': saved.id,
                'reportCode': saved.reportCode,
                'versionNumber': saved.versionNumber,
                'reportSha256': saved.reportSha256,
              },
            ),
          );
        } catch (_) {}
      }

      return Right(saved);
    } catch (e) {
      return Left(ReportGenerationFailure('Gagal membuat laporan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ActivityReportEntity>>> getReportsByTaskId(
    String taskId,
  ) async {
    try {
      final local = await _localDataSource.getReportsByTaskId(taskId);
      if (local.isNotEmpty) {
        return Right(local);
      }

      // Cloud fallback jika kosong di lokal
      try {
        final remote = await _remoteDataSource.getTaskReports(taskId);
        for (final item in remote) {
          await _localDataSource.insertReport(item);
        }
        return Right(remote);
      } catch (_) {
        return Right(local);
      }
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, ActivityReportEntity>> getReportById(
    String reportId,
  ) async {
    try {
      final local = await _localDataSource.getReportById(reportId);
      if (local != null) {
        return Right(local);
      }

      final remote = await _remoteDataSource.getReportById(reportId);
      if (remote != null) {
        await _localDataSource.insertReport(remote);
        return Right(remote);
      }

      return const Left(NotFoundFailure('Laporan tidak ditemukan.'));
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport({
    required String reportId,
    required String taskId,
  }) async {
    try {
      await _localDataSource.deleteReport(reportId);
      try {
        await _remoteDataSource.deleteReport(reportId);
      } catch (_) {}
      return const Right(null);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> verifyReportSha256({
    required String reportId,
    required String localPdfPath,
  }) async {
    try {
      final report = await _localDataSource.getReportById(reportId);
      if (report == null) {
        return const Left(NotFoundFailure('Data laporan tidak ditemukan.'));
      }

      final file = File(localPdfPath);
      if (!file.existsSync()) {
        return const Left(NotFoundFailure('File PDF tidak ditemukan di perangkat.'));
      }

      final bytes = await file.readAsBytes();
      final currentHash = sha256.convert(bytes).toString();

      final isMatch = currentHash.toLowerCase() == report.reportSha256.toLowerCase();
      return Right(isMatch);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }
}
