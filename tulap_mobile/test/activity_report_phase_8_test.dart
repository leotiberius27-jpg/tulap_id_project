import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/features/activity_report/data/datasources/activity_report_local_datasource.dart';
import 'package:tulap_mobile/features/activity_report/data/models/activity_report_model.dart';
import 'package:tulap_mobile/features/activity_report/data/services/report_data_assembler.dart';
import 'package:tulap_mobile/features/activity_report/data/services/report_validator.dart';
import 'package:tulap_mobile/features/activity_report/domain/entities/activity_report_entity.dart';
import 'package:tulap_mobile/features/activity_report/domain/entities/report_draft_data.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import 'package:tulap_mobile/features/expense_ocr/data/models/expense_note_model.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/entities/expense_note_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/task_detail/data/datasources/timeline_local_datasource.dart';
import 'package:tulap_mobile/features/task_detail/data/models/timeline_event_model.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/timeline_event_entity.dart';

class FakeGeotagCameraLocalDataSource implements GeotagCameraLocalDataSource {
  List<GeotagPhotoModel> photos = [];

  @override
  Future<List<GeotagPhotoModel>> getPhotosByTask(String taskId) async => photos;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseOcrLocalDataSource implements ExpenseOcrLocalDataSource {
  List<ExpenseNoteModel> expenses = [];

  @override
  Future<List<ExpenseNoteModel>> getNotesByTask(String taskId) async => expenses;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTimelineLocalDataSource implements TimelineLocalDataSource {
  List<TimelineEventModel> events = [];

  @override
  Future<List<TimelineEventModel>> getEventsByTask(String taskId) async => events;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  AuthUserEntity? storedUser;

  @override
  Future<AuthUserEntity?> getStoredUser() async => storedUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeActivityReportLocalDataSource implements ActivityReportLocalDataSource {
  final Map<String, List<ActivityReportModel>> _store = {};

  @override
  Future<ActivityReportModel> insertReport(ActivityReportModel model) async {
    _store.putIfAbsent(model.taskId, () => []);
    _store[model.taskId]!.removeWhere((r) => r.id == model.id);
    _store[model.taskId]!.insert(0, model);
    return model;
  }

  @override
  Future<List<ActivityReportModel>> getReportsByTaskId(String taskId) async {
    return _store[taskId] ?? [];
  }

  @override
  Future<ActivityReportModel?> getReportById(String reportId) async {
    for (final list in _store.values) {
      for (final item in list) {
        if (item.id == reportId) return item;
      }
    }
    return null;
  }

  @override
  Future<int> getNextVersionNumber(String taskId) async {
    final list = _store[taskId] ?? [];
    if (list.isEmpty) return 1;
    final maxVer = list.fold<int>(0, (max, r) => r.versionNumber > max ? r.versionNumber : max);
    return maxVer + 1;
  }

  @override
  Future<void> updateReport(ActivityReportModel model) async {
    await insertReport(model);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    for (final list in _store.values) {
      list.removeWhere((r) => r.id == reportId);
    }
  }

  @override
  Future<String> computeFileSha256(String filePath) async {
    return 'computed_sha256_mock';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 8: Smart Activity Report & LPJ Foundation', () {
    late TaskEntity testTask;
    late AuthUserEntity testUser;
    late List<GeotagPhotoModel> testPhotos;
    late List<ExpenseNoteModel> testExpenses;
    late List<TimelineEventModel> testTimeline;

    setUp(() {
      testTask = TaskEntity(
        id: 'task-lpj-001',
        taskCode: 'SPPD/2026/08/001',
        taskName: 'Inspeksi BTS Wilayah Timika Barat',
        destination: 'Distrik Mimika Barat, Papua Tengah',
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 8, 27),
        status: TaskStatusEntity.ongoing,
        assigneeId: 'user-001',
        assigneeName: 'Budi Santoso',
        budgetAmount: 5000000.0,
        checklistItems: const [],
        geotagPhotoCount: 2,
        expenseNoteCount: 2,
        description: 'Pemeriksaan rutin transmisi telekomunikasi dan catu daya BTS',
      );

      testUser = const AuthUserEntity(
        id: 'user-001',
        fullName: 'Budi Santoso',
        email: 'budi@mimika.go.id',
        nip: '198501012010011002',
        instansiName: 'Dinas Komunikasi dan Informatika',
        role: 'FIELD_STAFF',
      );

      testPhotos = [
        GeotagPhotoModel(
          id: 'photo-001',
          taskId: testTask.id,
          localFilePath: 'dummy/path/p1.jpg',
          latitude: -4.5468,
          longitude: 136.8837,
          plusCode: '6P27+XX Timika',
          altitude: 45.0,
          gpsAccuracyMeters: 3.5,
          serverTimestamp: DateTime(2026, 8, 25, 10, 30),
          caption: 'Kondisi tower utama',
          integrityHash: 'hash1',
          isMockLocationDetected: false,
          isRootedDeviceDetected: false,
          syncStatus: 'SYNCED',
        ),
        GeotagPhotoModel(
          id: 'photo-002',
          taskId: testTask.id,
          localFilePath: 'dummy/path/p2.jpg',
          latitude: -4.5470,
          longitude: 136.8840,
          plusCode: '6P27+YY Timika',
          altitude: 46.0,
          gpsAccuracyMeters: 4.0,
          serverTimestamp: DateTime(2026, 8, 25, 14, 15),
          caption: 'Pemeriksaan genset cadangan',
          integrityHash: 'hash2',
          isMockLocationDetected: false,
          isRootedDeviceDetected: false,
          syncStatus: 'SYNCED',
        ),
      ];

      testExpenses = [
        ExpenseNoteModel(
          id: 'exp-001',
          taskId: testTask.id,
          vendorName: 'Speedboat Papua Bahari',
          totalAmount: 1500000.0,
          transactionDate: DateTime(2026, 8, 25),
          category: ExpenseCategoryEntity.transportasiLain,
          localScanPath: 'dummy/path/receipt1.jpg',
          ocrRawText: 'SPEEDBOAT PAPUA BAHARI TOTAL 1500000',
          ocrConfidence: 0.95,
          verificationStatus: ExpenseVerificationStatus.userConfirmed,
          createdAt: DateTime(2026, 8, 25),
        ),
        ExpenseNoteModel(
          id: 'exp-002',
          taskId: testTask.id,
          vendorName: 'Rumah Makan Nusantara',
          totalAmount: 75000.0,
          transactionDate: DateTime(2026, 8, 25),
          category: ExpenseCategoryEntity.konsumsi,
          localScanPath: 'dummy/path/receipt2.jpg',
          ocrRawText: 'RM NUSANTARA TOTAL 75000',
          ocrConfidence: 0.92,
          verificationStatus: ExpenseVerificationStatus.userConfirmed,
          createdAt: DateTime(2026, 8, 25),
        ),
      ];

      testTimeline = [
        TimelineEventModel(
          id: 'tl-001',
          taskId: testTask.id,
          eventType: TimelineEventType.activityStarted,
          title: 'Kegiatan Dimulai',
          description: 'Berangkat menuju lokasi Timika Barat',
          eventTimestamp: DateTime(2026, 8, 25, 8, 0),
        ),
      ];
    });

    test('1. ReportDataAssembler compiles structured draft with deterministic narrative', () async {
      final fakeCamera = FakeGeotagCameraLocalDataSource()..photos = testPhotos;
      final fakeExpense = FakeExpenseOcrLocalDataSource()..expenses = testExpenses;
      final fakeTimeline = FakeTimelineLocalDataSource()..events = testTimeline;
      final fakeAuth = FakeAuthRepository()..storedUser = testUser;

      final assembler = ReportDataAssembler(
        cameraLocalDataSource: fakeCamera,
        expenseLocalDataSource: fakeExpense,
        timelineLocalDataSource: fakeTimeline,
        authRepository: fakeAuth,
      );

      final draft = await assembler.assemble(testTask);

      expect(draft.task.id, equals(testTask.id));
      expect(draft.selectedEvidence.length, equals(2));
      expect(draft.selectedExpenses.length, equals(2));
      expect(draft.totalExpenseSum, equals(1575000.0));
      expect(draft.implementerName, equals('Budi Santoso'));

      // Check narrative contains authoritative numeric facts
      expect(draft.narrative, contains('Inspeksi BTS Wilayah Timika Barat'));
      expect(draft.narrative, contains('2 foto bukti geotag'));
      expect(draft.narrative, contains('2 bukti nota transaksi'));
      expect(draft.narrative, contains('1.575.000'));
    });

    test('2. ReportValidator correctly detects blockers vs non-blocking warnings', () {
      final validator = ReportValidator();

      final validDraft = ReportDraftData(
        task: testTask,
        title: 'LAPORAN KEGIATAN INSPEKSI BTS',
        narrative: 'Pelaksanaan berjalan lancar.',
        selectedEvidence: testPhotos,
        selectedExpenses: testExpenses,
        selectedTimelineEvents: testTimeline,
        selectedNotes: const [],
        assembledAt: DateTime.now(),
      );

      final result = validator.validate(validDraft);
      expect(result.isReady, isTrue);
      expect(result.blockers, isEmpty);

      // Empty title should produce blocker
      final invalidDraft = validDraft.copyWith(title: '  ');
      final invalidResult = validator.validate(invalidDraft);
      expect(invalidResult.isReady, isFalse);
      expect(invalidResult.blockers.length, equals(1));
    });

    test('3. ActivityReportModel serialization to SQLite row and JSON is intact', () {
      final now = DateTime(2026, 8, 27, 12, 0);
      final model = ActivityReportModel(
        id: 'rep-001',
        taskId: testTask.id,
        userId: testUser.id,
        reportCode: 'LAP-20260827-REP001',
        reportType: 'ACTIVITY_REPORT',
        title: 'Laporan Akhir Tugas',
        summary: 'Ringkasan singkat pelaksanaan',
        narrative: 'Narasi lengkap...',
        periodStart: testTask.startDate,
        periodEnd: testTask.endDate,
        versionNumber: 1,
        status: ReportStatus.generated,
        pdfLocalPath: '/data/user/0/com.tulap.mobile/reports/rep-001.pdf',
        contentSnapshotJson: '{"version": 1, "total": 1575000}',
        reportSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        totalExpense: 1575000.0,
        evidenceCount: 2,
        receiptCount: 2,
        syncStatus: 'LOCAL_ONLY',
        createdAt: now,
      );

      final row = model.toRow();
      expect(row['id'], equals('rep-001'));
      expect(row['totalExpense'], equals(1575000.0));
      expect(row['reportSha256'], equals('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'));

      final restored = ActivityReportModel.fromRow(row);
      expect(restored.id, equals(model.id));
      expect(restored.reportCode, equals(model.reportCode));
      expect(restored.totalExpense, equals(model.totalExpense));
      expect(restored.versionNumber, equals(1));
    });

    test('4. Versioning preserves v1 when v2 is generated', () async {
      final mockLocal = FakeActivityReportLocalDataSource();

      // Create v1
      final v1 = ActivityReportModel(
        id: 'rep-v1',
        taskId: testTask.id,
        reportCode: 'LAP-20260827-001',
        title: 'Laporan v1',
        versionNumber: 1,
        contentSnapshotJson: '{"version": 1}',
        reportSha256: 'hash_v1',
        createdAt: DateTime(2026, 8, 27, 10, 0),
      );
      await mockLocal.insertReport(v1);

      // Check next version calculation
      final nextVer = await mockLocal.getNextVersionNumber(testTask.id);
      expect(nextVer, equals(2));

      // Create v2
      final v2 = ActivityReportModel(
        id: 'rep-v2',
        taskId: testTask.id,
        reportCode: 'LAP-20260827-002',
        title: 'Laporan v2',
        versionNumber: 2,
        contentSnapshotJson: '{"version": 2}',
        reportSha256: 'hash_v2',
        createdAt: DateTime(2026, 8, 27, 11, 0),
      );
      await mockLocal.insertReport(v2);

      // Verify both v1 and v2 exist in archive history
      final history = await mockLocal.getReportsByTaskId(testTask.id);
      expect(history.length, equals(2));
      expect(history.any((r) => r.versionNumber == 1), isTrue);
      expect(history.any((r) => r.versionNumber == 2), isTrue);
    });

    test('5. Reordering documentation & recalculating expenses behaves predictably', () {
      final initialDraft = ReportDraftData(
        task: testTask,
        title: 'Laporan',
        narrative: 'Narasi',
        selectedEvidence: testPhotos,
        selectedExpenses: testExpenses,
        selectedTimelineEvents: testTimeline,
        selectedNotes: const [],
        assembledAt: DateTime.now(),
      );

      expect(initialDraft.selectedEvidence.first.id, equals('photo-001'));
      expect(initialDraft.totalExpenseSum, equals(1575000.0));

      // Reorder photo 0 to 1
      final reordered = List<GeotagPhotoModel>.from(testPhotos.reversed);
      final draftReordered = initialDraft.copyWith(selectedEvidence: reordered);
      expect(draftReordered.selectedEvidence.first.id, equals('photo-002'));

      // Deselect 1 expense
      final filteredExpenses = [testExpenses.first];
      final draftRecalculated = initialDraft.copyWith(selectedExpenses: filteredExpenses);
      expect(draftRecalculated.totalExpenseSum, equals(1500000.0));
      expect(draftRecalculated.receiptCount, equals(1));
    });

    test('6. SHA-256 checksum detection matches unchanged content and rejects alteration', () {
      final originalData = utf8.encode('PDF DOCUMENT CONTENT STREAM 2026');
      final originalHash = sha256.convert(originalData).toString();

      final recomputedHash = sha256.convert(originalData).toString();
      expect(recomputedHash.toLowerCase(), equals(originalHash.toLowerCase()));

      final alteredData = utf8.encode('PDF DOCUMENT CONTENT STREAM 2026 MODIFIED');
      final alteredHash = sha256.convert(alteredData).toString();
      expect(alteredHash.toLowerCase(), isNot(equals(originalHash.toLowerCase())));
    });
  });
}
