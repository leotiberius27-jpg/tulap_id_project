import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/timeline_event_entity.dart';

/// TimelineRepository (Kontrak Interface Domain)
/// ----------------------------------------------------------------------
/// Menyediakan akses perekaman dan pembacaan linimasa kegiatan.
/// ----------------------------------------------------------------------
abstract class TimelineRepository {
  /// Merekam event baru ke linimasa lokal
  Future<Either<Failure, TimelineEventEntity>> recordEvent({
    required String taskId,
    required TimelineEventType eventType,
    required String title,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  });

  /// Mengambil daftar seluruh event linimasa untuk satu kegiatan (terurut kronologis)
  Future<Either<Failure, List<TimelineEventEntity>>> getTimelineEvents(
    String taskId,
  );
}
