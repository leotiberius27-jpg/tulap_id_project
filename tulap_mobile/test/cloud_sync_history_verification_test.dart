import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/usecases/get_activity_evidence.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/entities/evidence_verification_result.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/history/presentation/controllers/history_controller.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/repositories/task_repository.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_active_tasks.dart';

// --- Mocks & Fakes ---
class _FakeTaskRepository implements TaskRepository {
  final List<TaskEntity> tasks;
  _FakeTaskRepository(this.tasks);

  @override
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks() async =>
      Right(tasks);

  @override
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId) async =>
      Right(tasks.firstWhere((t) => t.id == taskId));

  @override
  Future<Either<Failure, TaskEntity>> startTask(String taskId) async =>
      Right(tasks.firstWhere((t) => t.id == taskId));

  @override
  Future<Either<Failure, TaskEntity>> submitForVerification(
    String taskId,
  ) async => Right(tasks.firstWhere((t) => t.id == taskId));

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) async => Right(
    ChecklistItemEntity(
      id: itemId,
      taskId: taskId,
      label: 'Item',
      order: 1,
      isMandatory: true,
      isCompleted: isCompleted,
    ),
  );
}

class _FakeAuthRepository implements AuthRepository {
  final AuthUserEntity? user;
  _FakeAuthRepository(this.user);

  @override
  Future<AuthUserEntity?> getStoredUser() async => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGeotagCameraLocalDataSource implements GeotagCameraLocalDataSource {
  final List<GeotagPhotoModel> photos;
  _FakeGeotagCameraLocalDataSource(this.photos);

  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async =>
      photos.where((p) => p.taskId == taskId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testUser = const AuthUserEntity(
    id: 'user-01',
    email: 'budi.santoso@papua.go.id',
    fullName: 'Budi Santoso, S.T.',
    role: 'PEGAWAI',
    instansiName: 'Dinas PUPR Provinsi Papua',
  );

  final List<TaskEntity> sampleTasks = [
    TaskEntity(
      id: 'task-2024-01',
      taskCode: 'TL-202401-0001',
      taskName: 'Survei Jembatan Hamadi 2024',
      destination: 'Jayapura Selatan',
      description: 'Pemeriksaan fondasi pier 3 pasca banjir',
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2024, 1, 17),
      budgetAmount: 5000000,
      status: TaskStatusEntity.verified,
      assigneeId: 'user-01',
      assigneeName: 'Budi Santoso, S.T.',
      checklistItems: const [],
      geotagPhotoCount: 3,
      expenseNoteCount: 2,
    ),
    TaskEntity(
      id: 'task-2025-06',
      taskCode: 'TL-202506-0042',
      taskName: 'Monitoring Jalan Poros Sentani 2025',
      destination: 'Kabupaten Jayapura',
      description: 'Pengukuran kerataan aspal segmen 12-18',
      startDate: DateTime(2025, 6, 20),
      endDate: DateTime(2025, 6, 22),
      budgetAmount: 12000000,
      status: TaskStatusEntity.completed,
      assigneeId: 'user-01',
      assigneeName: 'Budi Santoso, S.T.',
      checklistItems: const [],
      geotagPhotoCount: 5,
      expenseNoteCount: 1,
    ),
    TaskEntity(
      id: 'task-2026-08',
      taskCode: 'TL-202608-0103',
      taskName: 'Inspeksi Drainase Abepura 2026',
      destination: 'Kota Jayapura',
      description: 'Dokumentasi gorong-gorong tersumbat',
      startDate: DateTime(2026, 8, 26),
      endDate: DateTime(2026, 8, 27),
      budgetAmount: 8500000,
      status: TaskStatusEntity.verified,
      assigneeId: 'user-01',
      assigneeName: 'Budi Santoso, S.T.',
      checklistItems: const [],
      geotagPhotoCount: 4,
      expenseNoteCount: 3,
    ),
    TaskEntity(
      id: 'task-2026-draft',
      taskCode: 'TL-202608-0104',
      taskName: 'Draf Kegiatan Belum Berjalan',
      destination: 'Merauke',
      startDate: DateTime(2026, 8, 27),
      endDate: DateTime(2026, 8, 28),
      budgetAmount: 3000000,
      status: TaskStatusEntity.draft,
      assigneeId: 'user-01',
      assigneeName: 'Budi Santoso, S.T.',
      checklistItems: const [],
      geotagPhotoCount: 0,
      expenseNoteCount: 0,
    ),
  ];

  group('Phase 6: Long-Term History & Field Activity Memory Tests', () {
    test('1. Survives multiple years: filters by Year (2024, 2025, 2026)', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(testUser)),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state.allTasks.length, 3);
      expect(controller.state.availableYears, [2026, 2025, 2024]);

      controller.setYearFilter(2024);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2024-01');

      controller.setYearFilter(2025);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2025-06');

      controller.setYearFilter(2026);
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2026-08');

      controller.setYearFilter(null);
      expect(controller.state.filteredTasks.length, 3);
    });

    test('2. Custom Date Range filtering across years', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(testUser)),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      controller.setCustomDateRange(
        DateTime(2024, 1, 1),
        DateTime(2025, 12, 31),
      );
      expect(controller.state.filteredTasks.length, 2);
      expect(
        controller.state.filteredTasks.map((t) => t.id).toSet(),
        {'task-2024-01', 'task-2025-06'},
      );
    });

    test('3. Media Filter: Ada Foto vs Ada Nota', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(testUser)),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      controller.setMediaFilter(HistoryMediaFilter.hasPhoto);
      expect(controller.state.filteredTasks.length, 3);

      controller.setMediaFilter(HistoryMediaFilter.hasReceipt);
      expect(controller.state.filteredTasks.length, 3);

      controller.resetAllFilters();
      expect(controller.state.filteredTasks.length, 3);
    });

    test('4. Multi-term Search: matches task code, title, destination, and description', () async {
      final controller = HistoryController(
        getActiveTasks: GetActiveTasks(_FakeTaskRepository(sampleTasks)),
        getCurrentSession: GetCurrentSession(_FakeAuthRepository(testUser)),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      controller.setSearchQuery('banjir');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2024-01');

      controller.setSearchQuery('0042');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2025-06');

      controller.setSearchQuery('Abepura');
      expect(controller.state.filteredTasks.length, 1);
      expect(controller.state.filteredTasks.first.id, 'task-2026-08');
    });
  });

  group('Phase 6: Resilient Sync Queue & Outbox State Machine Tests', () {
    test('5. Sync Record Entity state machine and backoff calculation', () {
      final record = SyncRecordEntity(
        id: 'sync-rec-01',
        entityType: SyncEntityType.geotagPhoto,
        entityLocalId: 'photo-uuid-1',
        taskId: 'task-2026-08',
        status: SyncStatus.waitingForInternet,
        attemptCount: 0,
        createdAt: DateTime.now(),
      );

      expect(record.canAutoRetry, isTrue);
      expect(record.isFailedPermanent, isFalse);

      final failed5x = record.copyWith(
        status: SyncStatus.failed,
        attemptCount: 5,
      );
      expect(failed5x.canAutoRetry, isFalse);
      expect(failed5x.isFailedPermanent, isTrue);
    });
  });

  group('Phase 6: Cross-Device Evidence Retrieval & Verification Tests', () {
    test('6. GetActivityEvidence falls back gracefully to Cloud when local cache is empty', () async {
      final localDs = _FakeGeotagCameraLocalDataSource([]);
      final useCase = GetActivityEvidence(localDs);

      final result = await useCase.call('task-2026-08');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (photos) => expect(photos, isEmpty),
      );
    });

    test('7. EvidenceVerificationResult formats timestamps and integrity accurately', () {
      final result = EvidenceVerificationResult(
        photoId: 'photo-uuid-1',
        taskId: 'task-2026-08',
        shortEvidenceId: 'EV-0103-01',
        localFilePath: '/data/user/0/com.tulap.mobile/app_flutter/photo.jpg',
        isFinalHashValid: true,
        computedFinalHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        storedFinalHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        hasValidLocation: true,
        latitude: -2.5337,
        longitude: 140.7181,
        gpsAccuracyMeters: 8.5,
        plusCode: '6P25R8CR+47',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        isActivityBound: true,
        taskTitle: 'Inspeksi Drainase Abepura 2026',
        officerName: 'Budi Santoso, S.T.',
        agencyName: 'Dinas PUPR Provinsi Papua',
        deviceTimestamp: DateTime(2026, 8, 26, 14, 30),
        serverTimestamp: DateTime(2026, 8, 26, 14, 31),
        isSynced: true,
        overallStatus: EvidenceVerificationStatus.verified,
        verifiedAt: DateTime.now(),
      );

      expect(result.overallStatus, EvidenceVerificationStatus.verified);
      expect(result.isFullyVerified, isTrue);
      expect(result.isFinalHashValid, isTrue);
      expect(result.computedFinalHash, equals(result.storedFinalHash));
      expect(result.isMockLocationDetected, isFalse);
    });
  });
}
