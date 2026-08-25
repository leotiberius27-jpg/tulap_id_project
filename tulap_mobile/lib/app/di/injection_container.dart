import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
import '../../core/geo/fast_location_service.dart';
import '../../core/geo/plus_code_generator.dart';
import '../../core/geo/reverse_geocoder.dart';
import '../../core/geo/static_map_thumbnail.dart';
import '../../core/imaging/watermark_compositor.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_info.dart';
import '../../core/ocr/receipt_ocr_engine.dart';
import '../../core/ocr/receipt_parser.dart';
import '../../core/security/hash_generator.dart';
import '../../core/security/mock_location_detector.dart';
import '../../core/security/root_detector.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/security/oauth_sign_in_service.dart';
import '../../core/session/auth_session_manager.dart';
import '../../core/sync/background_sync_service.dart';
import '../../core/theme/theme_controller.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/disable_biometric_login.dart';
import '../../features/auth/domain/usecases/enable_biometric_login.dart';
import '../../features/auth/domain/usecases/forgot_password.dart';
import '../../features/auth/domain/usecases/get_biometric_greeting_user.dart';
import '../../features/auth/domain/usecases/get_current_session.dart';
import '../../features/auth/domain/usecases/is_biometric_login_enabled.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/login_with_apple.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/restore_biometric_session.dart';
import '../../features/auth/domain/usecases/self_register.dart';
import '../../features/auth/domain/usecases/update_user_profile.dart';

import '../../features/account/data/datasources/account_local_datasource.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/clear_app_cache.dart';
import '../../features/account/domain/usecases/get_account_settings.dart';
import '../../features/account/domain/usecases/get_storage_breakdown.dart';
import '../../features/account/domain/usecases/save_camera_settings.dart';
import '../../features/account/domain/usecases/save_notification_settings.dart';

import '../../features/expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../features/expense_ocr/data/repositories/expense_ocr_repository_impl.dart';
import '../../features/expense_ocr/domain/repositories/expense_ocr_repository.dart';
import '../../features/expense_ocr/domain/usecases/save_expense_note.dart';
import '../../features/expense_ocr/domain/usecases/scan_receipt.dart';

import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/services/notification_coordinator.dart';
import '../../features/notifications/domain/usecases/create_or_update_notification.dart';
import '../../features/notifications/domain/usecases/delete_read_notifications.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/get_unread_notification_count.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';

import '../../features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../features/geotag_camera/data/repositories/geotag_camera_repository_impl.dart';
import '../../features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import '../../features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import '../../features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../features/geotag_camera/domain/usecases/validate_location_integrity.dart';

import '../../features/sync_queue/data/datasources/sync_local_datasource.dart';
import '../../features/sync_queue/data/datasources/sync_remote_datasource.dart';
import '../../features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import '../../features/sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../features/sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../features/sync_queue/domain/usecases/process_sync_queue.dart';

import '../../features/task_detail/data/datasources/activity_note_local_datasource.dart';
import '../../features/task_detail/data/datasources/task_local_datasource.dart';
import '../../features/task_detail/data/datasources/task_remote_datasource.dart';
import '../../features/task_detail/data/datasources/timeline_local_datasource.dart';
import '../../features/task_detail/data/repositories/activity_note_repository_impl.dart';
import '../../features/task_detail/data/repositories/task_repository_impl.dart';
import '../../features/task_detail/data/repositories/timeline_repository_impl.dart';
import '../../features/task_detail/domain/repositories/activity_note_repository.dart';
import '../../features/task_detail/domain/repositories/task_repository.dart';
import '../../features/task_detail/domain/repositories/timeline_repository.dart';
import '../../features/task_detail/domain/usecases/add_activity_note.dart';
import '../../features/task_detail/domain/usecases/create_activity.dart';
import '../../features/task_detail/domain/usecases/get_active_tasks.dart';
import '../../features/task_detail/domain/usecases/get_activity_notes.dart';
import '../../features/task_detail/domain/usecases/get_task_detail.dart';
import '../../features/task_detail/domain/usecases/get_task_expenses.dart';
import '../../features/task_detail/domain/usecases/get_timeline_events.dart';
import '../../features/task_detail/domain/usecases/pick_active_task.dart';
import '../../features/task_detail/domain/usecases/record_timeline_event.dart';
import '../../features/task_detail/domain/usecases/start_task.dart';
import '../../features/task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../features/task_detail/domain/usecases/toggle_checklist_item.dart';

/// Service locator global - dipanggil sebagai `sl<TipeClass>()` dari
/// mana pun di aplikasi setelah `initDependencies()` dijalankan.
final GetIt sl = GetIt.instance;

/// Dibaca dari `--dart-define=API_BASE_URL=...` saat build, agar build
/// rilis (staging/production) bisa menunjuk ke backend sungguhan tanpa
/// mengubah kode - lihat RUNBOOK.md bagian "Build untuk rilis". Nilai
/// default di bawah HANYA untuk dev lokal: 10.0.2.2 adalah alias khusus
/// Android emulator untuk mengakses localhost komputer host tempat
/// `tulap_backend` dijalankan (RUNBOOK.md TAHAP 3) - ganti ke
/// 'http://localhost:3000' untuk iOS Simulator/Chrome, atau
/// 'http://<IP_LAN_komputer_Anda>:3000' untuk HP fisik, lewat
/// --dart-define alih-alih mengedit baris ini.
const String _kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000',
);

/// initDependencies
/// ----------------------------------------------------------------------
/// Titik inisialisasi TUNGGAL seluruh dependency aplikasi. Dipanggil
/// SEKALI di `main.dart` sebelum `runApp()`. Urutan registrasi PENTING:
/// dependency yang levelnya lebih rendah (core, database) harus
/// terdaftar SEBELUM dependency yang bergantung padanya (repository,
/// usecase).
///
/// CATATAN PENTING soal CameraController: controller ini butuh
/// `CameraDescription` yang hanya bisa didapat via
/// `availableCameras()` (async, dan berbeda per perangkat). Karena
/// itu, `CameraController` TIDAK didaftarkan di sini sebagai singleton
/// global, melainkan dibuat per-sesi di halaman kamera/scanner itu
/// sendiri (lihat catatan di `registerCameraDependentServices` di
/// bawah), lalu repository yang bergantung padanya didaftarkan ulang
/// (`unregister` + `registerLazySingleton`) tiap kali layar kamera dibuka.
/// ----------------------------------------------------------------------
Future<void> initDependencies({Database? database}) async {
  // ============================================================
  // CORE - Database, Network, Security, OCR
  // ============================================================
  if (database != null) {
    if (sl.isRegistered<Database>()) {
      sl.unregister<Database>();
    }
    sl.registerSingleton<Database>(database);
  } else if (!sl.isRegistered<Database>()) {
    final Database db = await LocalDatabase.instance;
    sl.registerSingleton<Database>(db);
  }

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(sl()));
  sl.registerLazySingleton<DioClient>(() => DioClient(baseUrl: _kApiBaseUrl));

  sl.registerLazySingleton<MockLocationDetector>(() => MockLocationDetector());
  sl.registerLazySingleton<RootDetector>(() => RootDetector());
  sl.registerLazySingleton<HashGenerator>(() => HashGenerator());
  sl.registerLazySingleton<PlusCodeGenerator>(() => PlusCodeGenerator());
  sl.registerLazySingleton<ReverseGeocoder>(() => ReverseGeocoder());
  sl.registerLazySingleton<FastLocationService>(() {
    final service = FastLocationService.instance;
    service.setReverseGeocoder(sl());
    return service;
  });
  sl.registerLazySingleton<StaticMapThumbnail>(() => StaticMapThumbnail());
  sl.registerLazySingleton<WatermarkCompositor>(() => WatermarkCompositor());

  sl.registerLazySingleton<ReceiptOcrEngine>(() => ReceiptOcrEngine());
  sl.registerLazySingleton<ReceiptParser>(() => ReceiptParser());

  // ============================================================
  // AUTH - didaftarkan lebih dulu karena main.dart butuh
  // GetCurrentSession SEBELUM runApp() untuk menentukan rute awal
  // (Login atau Beranda).
  // ============================================================
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<AuthSessionManager>(
    () => AuthSessionManager(authRepository: sl()),
  );
  sl.registerLazySingleton<Login>(() => Login(sl(), sl()));
  sl.registerLazySingleton<GetCurrentSession>(() => GetCurrentSession(sl()));
  sl.registerLazySingleton<Logout>(() => Logout(sl(), sl()));
  sl.registerLazySingleton<SelfRegister>(() => SelfRegister(sl(), sl()));
  sl.registerLazySingleton<ForgotPassword>(() => ForgotPassword(sl()));
  sl.registerLazySingleton<ResetPassword>(() => ResetPassword(sl()));
  sl.registerLazySingleton<LoginWithGoogle>(() => LoginWithGoogle(sl(), sl()));
  sl.registerLazySingleton<LoginWithApple>(() => LoginWithApple(sl(), sl()));
  sl.registerLazySingleton<IsBiometricLoginEnabled>(
    () => IsBiometricLoginEnabled(sl()),
  );
  sl.registerLazySingleton<EnableBiometricLogin>(
    () => EnableBiometricLogin(sl()),
  );
  sl.registerLazySingleton<DisableBiometricLogin>(
    () => DisableBiometricLogin(sl()),
  );
  sl.registerLazySingleton<GetBiometricGreetingUser>(
    () => GetBiometricGreetingUser(sl()),
  );
  sl.registerLazySingleton<RestoreBiometricSession>(
    () => RestoreBiometricSession(sl(), sl()),
  );
  sl.registerLazySingleton<UpdateUserProfile>(() => UpdateUserProfile(sl(), sl()));
  sl.registerLazySingleton<BiometricAuthService>(() => BiometricAuthService());
  sl.registerLazySingleton<OAuthSignInService>(() => OAuthSignInService());

  // ============================================================
  // SYNC QUEUE - didaftarkan lebih dulu karena geotag_camera &
  // expense_ocr bergantung pada EnqueueSyncItem.
  // ============================================================
  sl.registerLazySingleton<SyncLocalDataSource>(
    () => SyncLocalDataSource(sl()),
  );
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSource(dioClient: sl(), database: sl()),
  );
  sl.registerLazySingleton<SyncQueueRepository>(
    () => SyncQueueRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<EnqueueSyncItem>(() => EnqueueSyncItem(sl()));
  sl.registerLazySingleton<ProcessSyncQueue>(
    () => ProcessSyncQueue(repository: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<BackgroundSyncService>(
    () => BackgroundSyncService(processSyncQueue: sl(), networkInfo: sl()),
  );

  // ============================================================
  // EXPENSE OCR - datasource lokal tidak butuh CameraController,
  // jadi bisa didaftarkan sebagai singleton biasa di sini. Repository-
  // ============================================================
  // EXPENSE OCR - didaftarkan secara permanen & lengkap di sini
  // ============================================================
  sl.registerLazySingleton<ExpenseOcrLocalDataSource>(
    () => ExpenseOcrLocalDataSource(
      ocrEngine: sl(),
      parser: sl(),
      database: sl(),
    ),
  );
  sl.registerLazySingleton<ExpenseOcrRepository>(
    () => ExpenseOcrRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ScanReceipt>(() => ScanReceipt(sl()));
  sl.registerLazySingleton<ConfirmAndSaveExpenseNote>(
    () => ConfirmAndSaveExpenseNote(repository: sl(), enqueueSyncItem: sl()),
  );

  // ============================================================
  // GEOTAG CAMERA - didaftarkan secara permanen & lengkap di sini
  // ============================================================
  sl.registerLazySingleton<GeotagCameraLocalDataSource>(
    () => GeotagCameraLocalDataSource(
      hashGenerator: sl(),
      watermarkCompositor: sl(),
      database: sl(),
    ),
  );
  sl.registerLazySingleton<GeotagCameraRepository>(
    () => GeotagCameraRepositoryImpl(
      localDataSource: sl(),
      mockLocationDetector: sl(),
      rootDetector: sl(),
      enqueueSyncItem: sl(),
      getCurrentSession: sl(),
      plusCodeGenerator: sl(),
      reverseGeocoder: sl(),
      staticMapThumbnail: sl(),
    ),
  );
  sl.registerLazySingleton<CaptureGeotaggedPhoto>(
    () => CaptureGeotaggedPhoto(sl()),
  );
  sl.registerLazySingleton<GetTaskPhotoPreviews>(
    () => GetTaskPhotoPreviews(sl()),
  );

  // ============================================================
  // TASK DETAIL - tidak bergantung pada CameraController, jadi
  // seluruhnya bisa didaftarkan sebagai singleton global di sini.
  // ============================================================
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSource(sl()),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      enqueueSyncItem: sl(),
    ),
  );
  sl.registerLazySingleton<GetTaskDetail>(() => GetTaskDetail(sl()));
  sl.registerLazySingleton<ToggleChecklistItem>(
    () => ToggleChecklistItem(sl()),
  );
  sl.registerLazySingleton<StartTask>(() => StartTask(sl()));
  sl.registerLazySingleton<SubmitTaskForVerification>(
    () => SubmitTaskForVerification(sl()),
  );
  sl.registerLazySingleton<GetActiveTasks>(() => GetActiveTasks(sl()));
  sl.registerLazySingleton<PickActiveTask>(() => PickActiveTask(sl()));
  sl.registerLazySingleton<CreateActivity>(
    () => CreateActivity(
      localDataSource: sl(),
      timelineDataSource: sl(),
      enqueueSyncItem: sl(),
    ),
  );

  // --- TIMELINE EVENTS ---
  sl.registerLazySingleton<TimelineLocalDataSource>(
    () => TimelineLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<TimelineRepository>(
    () => TimelineRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<RecordTimelineEvent>(
    () => RecordTimelineEvent(sl()),
  );
  sl.registerLazySingleton<GetTimelineEvents>(() => GetTimelineEvents(sl()));

  // --- ACTIVITY NOTES (Catatan Lapangan) ---
  sl.registerLazySingleton<ActivityNoteLocalDatasource>(
    () => ActivityNoteLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<ActivityNoteRepository>(
    () => ActivityNoteRepositoryImpl(
      localDatasource: sl(),
      timelineRepository: sl(),
    ),
  );
  sl.registerLazySingleton<GetActivityNotes>(() => GetActivityNotes(sl()));
  sl.registerLazySingleton<AddActivityNote>(() => AddActivityNote(sl()));

  // --- TASK EXPENSES (Nota & Pengeluaran) ---
  sl.registerLazySingleton<GetTaskExpenses>(() => GetTaskExpenses(sl()));

  // ============================================================
  // NOTIFICATIONS (Offline-First Notification Center)
  // ============================================================
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      authSessionManager: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<GetNotifications>(() => GetNotifications(sl()));
  sl.registerLazySingleton<GetUnreadNotificationCount>(
    () => GetUnreadNotificationCount(sl()),
  );
  sl.registerLazySingleton<MarkNotificationRead>(
    () => MarkNotificationRead(sl()),
  );
  sl.registerLazySingleton<MarkAllNotificationsRead>(
    () => MarkAllNotificationsRead(sl()),
  );
  sl.registerLazySingleton<DeleteReadNotifications>(
    () => DeleteReadNotifications(sl()),
  );
  sl.registerLazySingleton<CreateOrUpdateNotification>(
    () => CreateOrUpdateNotification(sl()),
  );
  sl.registerLazySingleton<NotificationCoordinator>(
    () => NotificationCoordinator(
      createOrUpdateNotification: sl(),
      notificationsRepository: sl(),
      authSessionManager: sl(),
    ),
  );

  // ============================================================
  // LOCATION - ValidateLocationIntegrity
  // ============================================================
  sl.registerLazySingleton<ValidateLocationIntegrity>(
    () => ValidateLocationIntegrity(
      mockLocationDetector: sl(),
      rootDetector: sl(),
    ),
  );

  // ============================================================
  // ACCOUNT & SETTINGS
  // ============================================================
  sl.registerLazySingleton<AccountLocalDataSource>(
    () => AccountLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<ThemeController>(
    () => ThemeController(localDataSource: sl()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<GetAccountSettings>(() => GetAccountSettings(sl()));
  sl.registerLazySingleton<SaveCameraSettings>(() => SaveCameraSettings(sl()));
  sl.registerLazySingleton<SaveNotificationSettings>(
    () => SaveNotificationSettings(sl()),
  );
  sl.registerLazySingleton<GetStorageBreakdown>(
    () => GetStorageBreakdown(sl()),
  );
  sl.registerLazySingleton<ClearAppCache>(() => ClearAppCache(sl()));
}

/// registerCameraSession
/// ----------------------------------------------------------------------
/// Menautkan instance `CameraController` aktif ke repository kamera
/// dan OCR yang sudah terdaftar di GetIt.
/// ----------------------------------------------------------------------
void registerCameraSession(CameraController controller) {
  if (sl.isRegistered<GeotagCameraRepository>()) {
    final repo = sl<GeotagCameraRepository>();
    if (repo is GeotagCameraRepositoryImpl) {
      repo.attachCameraController(controller);
    }
  }
  if (sl.isRegistered<ExpenseOcrRepository>()) {
    final repo = sl<ExpenseOcrRepository>();
    if (repo is ExpenseOcrRepositoryImpl) {
      repo.attachCameraController(controller);
    }
  }
}

/// unregisterCameraSession
/// ----------------------------------------------------------------------
/// Melepaskan referensi `CameraController` dari repository saat halaman
/// kamera/scanner di-dispose untuk mencegah memory leak.
/// ----------------------------------------------------------------------
void unregisterCameraSession() {
  if (sl.isRegistered<GeotagCameraRepository>()) {
    final repo = sl<GeotagCameraRepository>();
    if (repo is GeotagCameraRepositoryImpl) {
      repo.detachCameraController();
    }
  }
  if (sl.isRegistered<ExpenseOcrRepository>()) {
    final repo = sl<ExpenseOcrRepository>();
    if (repo is ExpenseOcrRepositoryImpl) {
      repo.detachCameraController();
    }
  }
}
