import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/geo/fast_location_service.dart';
import 'package:tulap_mobile/core/geo/reverse_geocoder.dart';
import 'package:tulap_mobile/core/session/auth_session_manager.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/repositories/expense_ocr_repository.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/save_expense_note.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/usecases/scan_receipt.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/controllers/geotag_camera_controller.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/get_task_detail.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/start_task.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/submit_task_for_verification.dart';
import 'package:tulap_mobile/features/task_detail/domain/usecases/toggle_checklist_item.dart';
import 'package:tulap_mobile/features/task_detail/presentation/controllers/task_detail_controller.dart';
import 'package:tulap_mobile/features/account/domain/repositories/account_repository.dart';
import 'package:tulap_mobile/features/account/domain/usecases/clear_app_cache.dart';
import 'package:tulap_mobile/features/account/domain/usecases/get_account_settings.dart';
import 'package:tulap_mobile/features/account/domain/usecases/get_storage_breakdown.dart';
import 'package:tulap_mobile/features/account/domain/usecases/save_camera_settings.dart';
import 'package:tulap_mobile/features/account/domain/usecases/save_notification_settings.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/update_user_profile.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:sqflite/sqflite.dart';

class _FakeDatabase extends Fake implements Database {
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async => [];

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async => [{'count': 0}];

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async => 1;

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async => 1;

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async => 1;

  @override
  Batch batch() => _FakeBatch();
}

class _FakeBatch extends Fake implements Batch {
  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {}

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async => [];
}

class _FakeNetworkInfo extends NetworkInfo {
  _FakeNetworkInfo() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dependency container sebelum pengujian
    await initDependencies(database: _FakeDatabase());

    // Override NetworkInfo with fake for headless test environment
    if (sl.isRegistered<NetworkInfo>()) {
      sl.unregister<NetworkInfo>();
    }
    sl.registerLazySingleton<NetworkInfo>(() => _FakeNetworkInfo());
  });

  group('GetIt Dependency Injection Graph Verification', () {
    test(
      'Geotag Camera dependencies are all registered and resolve cleanly',
      () {
        expect(sl.isRegistered<GeotagCameraRepository>(), isTrue);
        expect(sl.isRegistered<CaptureGeotaggedPhoto>(), isTrue);
        expect(sl.isRegistered<GetTaskPhotoPreviews>(), isTrue);
        expect(sl.isRegistered<ValidateLocationIntegrity>(), isTrue);
        expect(sl.isRegistered<ReverseGeocoder>(), isTrue);
        expect(sl.isRegistered<FastLocationService>(), isTrue);

        expect(() => sl<GeotagCameraRepository>(), returnsNormally);
        expect(() => sl<CaptureGeotaggedPhoto>(), returnsNormally);
        expect(() => sl<GetTaskPhotoPreviews>(), returnsNormally);
        expect(() => sl<ValidateLocationIntegrity>(), returnsNormally);
        expect(() => sl<ReverseGeocoder>(), returnsNormally);
        expect(() => sl<FastLocationService>(), returnsNormally);
      },
    );

    test('Expense OCR dependencies are all registered and resolve cleanly', () {
      expect(sl.isRegistered<ExpenseOcrRepository>(), isTrue);
      expect(sl.isRegistered<ScanReceipt>(), isTrue);
      expect(sl.isRegistered<ConfirmAndSaveExpenseNote>(), isTrue);

      expect(() => sl<ExpenseOcrRepository>(), returnsNormally);
      expect(() => sl<ScanReceipt>(), returnsNormally);
      expect(() => sl<ConfirmAndSaveExpenseNote>(), returnsNormally);
    });

    test(
      'GeotagCameraController can be constructed with DI dependencies directly',
      () {
        final controller = GeotagCameraController(
          validateLocationIntegrity: sl<ValidateLocationIntegrity>(),
          captureGeotaggedPhoto: sl<CaptureGeotaggedPhoto>(),
          getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
          reverseGeocoder: sl<ReverseGeocoder>(),
          taskId: 'TL-TEST-001',
        );

        expect(controller, isNotNull);
        expect(controller.state.captureStatus, equals(CaptureViewStatus.idle));
        controller.dispose();
      },
    );

    test(
      'Account and Settings dependencies are all registered and resolve cleanly',
      () {
        expect(sl.isRegistered<AccountRepository>(), isTrue);
        expect(sl.isRegistered<GetAccountSettings>(), isTrue);
        expect(sl.isRegistered<SaveCameraSettings>(), isTrue);
        expect(sl.isRegistered<SaveNotificationSettings>(), isTrue);
        expect(sl.isRegistered<GetStorageBreakdown>(), isTrue);
        expect(sl.isRegistered<ClearAppCache>(), isTrue);
        expect(sl.isRegistered<UpdateUserProfile>(), isTrue);
        expect(sl.isRegistered<AuthSessionManager>(), isTrue);

        expect(() => sl<AccountRepository>(), returnsNormally);
        expect(() => sl<GetAccountSettings>(), returnsNormally);
        expect(() => sl<SaveCameraSettings>(), returnsNormally);
        expect(() => sl<SaveNotificationSettings>(), returnsNormally);
        expect(() => sl<GetStorageBreakdown>(), returnsNormally);
        expect(() => sl<ClearAppCache>(), returnsNormally);
        expect(() => sl<UpdateUserProfile>(), returnsNormally);
        expect(() => sl<AuthSessionManager>(), returnsNormally);
      },
    );

    test(
      'TaskDetailController can be constructed with DI dependencies directly',
      () {
        final controller = TaskDetailController(
          getTaskDetail: sl<GetTaskDetail>(),
          toggleChecklistItem: sl<ToggleChecklistItem>(),
          startTask: sl<StartTask>(),
          submitForVerification: sl<SubmitTaskForVerification>(),
          getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
          taskId: 'TL-TEST-002',
        );

        expect(controller, isNotNull);
        expect(controller.state.status, equals(TaskDetailStatus.loading));
        controller.dispose();
      },
    );
  });
}
