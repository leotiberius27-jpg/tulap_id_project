import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/camera/camera_capability_service.dart';
import '../../core/camera/camera_level_sensor_service.dart';
import '../../core/camera/file_naming_service.dart';
import '../../core/database/local_database.dart';
import '../../core/geo/fast_location_service.dart';
import '../../core/geo/mini_map_renderer.dart';
import '../../core/geo/plus_code_generator.dart';
import '../../core/geo/reverse_geocoder.dart';
import '../../core/geo/static_map_thumbnail.dart';
import '../../core/imaging/watermark_compositor.dart';
import '../../core/map/map_launcher_service.dart';
import '../../core/media/media_share_service.dart';
import '../../core/media/media_thumbnail_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_info.dart';
import '../../core/ocr/receipt_ocr_engine.dart';
import '../../core/ocr/receipt_parser.dart';
import '../../core/qr/qr_location_generator.dart';
import '../../core/security/hash_generator.dart';
import '../../core/security/mock_location_detector.dart';
import '../../core/security/report_security_event.dart';
import '../../core/security/root_detector.dart';
import '../../core/security/security_event_local_datasource.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/security/oauth_sign_in_service.dart';
import '../../core/session/auth_session_manager.dart';
import '../../core/sync/background_sync_service.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/localization/language_controller.dart';

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
import '../../features/auth/domain/usecases/login_with_facebook.dart';
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
import '../../features/expense_ocr/domain/usecases/delete_expense_note.dart';
import '../../features/expense_ocr/domain/usecases/save_expense_note.dart';
import '../../features/expense_ocr/domain/usecases/save_manual_expense.dart';
import '../../features/expense_ocr/domain/usecases/scan_receipt.dart';
import '../../features/expense_ocr/domain/usecases/update_expense_note.dart';

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
import '../../features/geotag_camera/data/repositories/camera_preferences_repository_impl.dart';
import '../../features/geotag_camera/data/repositories/geotag_camera_repository_impl.dart';
import '../../features/geotag_camera/data/repositories/template_repository_impl.dart';
import '../../features/geotag_camera/domain/repositories/camera_preferences_repository.dart';
import '../../features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import '../../features/geotag_camera/domain/repositories/template_repository.dart';
import '../../features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import '../../features/geotag_camera/domain/usecases/create_evidence.dart';
import '../../features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import '../../features/evidence_verification/domain/usecases/verify_evidence_integrity.dart';
import '../../features/evidence_gallery/domain/usecases/delete_evidence.dart';
import '../../features/evidence_gallery/domain/usecases/get_activity_evidence.dart';
import '../../features/evidence_gallery/domain/usecases/share_evidence.dart';

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

import '../../features/subscription/data/datasources/payments_remote_datasource.dart';
import '../../features/subscription/data/datasources/subscription_local_datasource.dart';
import '../../features/subscription/data/datasources/subscription_remote_datasource.dart';
import '../../features/subscription/data/repositories/payment_repository_impl.dart';
import '../../features/subscription/data/repositories/plan_repository_impl.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/payment_repository.dart';
import '../../features/subscription/domain/repositories/plan_repository.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/check_activity_quota.dart';
import '../../features/subscription/domain/usecases/check_payment_status.dart';
import '../../features/subscription/domain/usecases/create_checkout.dart';
import '../../features/subscription/domain/usecases/get_current_subscription.dart';
import '../../features/subscription/domain/usecases/get_payment_detail.dart';
import '../../features/subscription/domain/usecases/get_payment_history.dart';
import '../../features/subscription/domain/usecases/get_plans.dart';
import '../../features/subscription/domain/usecases/get_subscription_usage.dart';
import '../../features/subscription/domain/usecases/select_plan.dart';

import '../../features/activity_report/data/datasources/activity_report_local_datasource.dart';
import '../../features/activity_report/data/datasources/activity_report_remote_datasource.dart';
import '../../features/activity_report/data/repositories/activity_report_repository_impl.dart';
import '../../features/activity_report/data/services/pdf_report_generator.dart';
import '../../features/activity_report/data/services/report_data_assembler.dart';
import '../../features/activity_report/data/services/report_validator.dart';
import '../../features/activity_report/domain/repositories/activity_report_repository.dart';
import '../../features/activity_report/domain/usecases/assemble_report_draft.dart';
import '../../features/activity_report/domain/usecases/delete_activity_report.dart';
import '../../features/activity_report/domain/usecases/generate_activity_report_pdf.dart';
import '../../features/activity_report/domain/usecases/get_task_reports.dart';
import '../../features/activity_report/domain/usecases/validate_report_draft.dart';
import '../../features/activity_report/domain/usecases/verify_report_sha256.dart';

import '../../features/travel_mission/data/datasources/travel_local_datasource.dart';
import '../../features/travel_mission/data/datasources/travel_remote_datasource.dart';
import '../../features/travel_mission/data/repositories/travel_repository_impl.dart';
import '../../features/travel_mission/data/services/pdf_lpj_package_generator.dart';
import '../../features/travel_mission/data/services/travel_completeness_service.dart';
import '../../features/travel_mission/data/services/travel_expense_aggregator.dart';
import '../../features/travel_mission/domain/repositories/travel_repository.dart';
import '../../features/travel_mission/domain/usecases/add_supporting_document.dart';
import '../../features/travel_mission/domain/usecases/create_travel_mission.dart';
import '../../features/travel_mission/domain/usecases/generate_lpj_package.dart';
import '../../features/travel_mission/domain/usecases/get_travel_mission_detail.dart';
import '../../features/travel_mission/domain/usecases/get_travel_missions.dart';
import '../../features/travel_mission/presentation/controllers/travel_mission_detail_controller.dart';
import '../../features/travel_mission/presentation/controllers/travel_mission_list_controller.dart';

import '../../features/search_archive/data/datasources/search_local_datasource.dart';
import '../../features/search_archive/data/datasources/search_remote_datasource.dart';
import '../../features/search_archive/data/repositories/search_archive_repository_impl.dart';
import '../../features/search_archive/data/services/search_query_parser.dart';
import '../../features/search_archive/data/services/search_result_merger.dart';
import '../../features/search_archive/data/services/search_index_service.dart';
import '../../features/search_archive/data/services/semantic_search_foundation.dart';
import '../../features/search_archive/domain/repositories/search_archive_repository.dart';
import '../../features/search_archive/domain/usecases/unified_search.dart';
import '../../features/search_archive/domain/usecases/get_recent_searches.dart';
import '../../features/search_archive/domain/usecases/save_recent_search.dart';
import '../../features/search_archive/domain/usecases/clear_recent_searches.dart';
import '../../features/search_archive/domain/usecases/rebuild_search_index.dart';
import '../../features/search_archive/domain/usecases/get_available_years.dart';
import '../../features/search_archive/presentation/controllers/search_archive_controller.dart';

import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/data/services/dashboard_insight_engine.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_analytics.dart';

import '../../features/assistant/data/datasources/assistant_local_datasource.dart';
import '../../features/assistant/data/datasources/assistant_remote_datasource.dart';
import '../../features/assistant/data/repositories/assistant_repository_impl.dart';
import '../../features/assistant/domain/repositories/assistant_repository.dart';
import '../../features/assistant/domain/usecases/ask_assistant.dart';
import '../../features/assistant/domain/usecases/get_assistant_suggestions.dart';
import '../../features/assistant/presentation/controllers/assistant_controller.dart';
import '../../features/assistant/presentation/controllers/tula_position_store.dart';
import '../../features/assistant/presentation/controllers/tula_visibility_controller.dart';

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
  sl.registerLazySingleton<QrLocationGenerator>(() => QrLocationGenerator());
  sl.registerLazySingleton<MiniMapRenderer>(() => MiniMapRenderer());
  sl.registerLazySingleton<WatermarkCompositor>(
    () => WatermarkCompositor(qrGenerator: sl(), miniMapRenderer: sl()),
  );
  sl.registerLazySingleton<TemplateRepository>(() => TemplateRepositoryImpl());
  sl.registerLazySingleton<CameraPreferencesRepository>(
    () => CameraPreferencesRepositoryImpl(),
  );
  sl.registerLazySingleton<CameraCapabilityService>(
    () => CameraCapabilityService(),
  );
  sl.registerLazySingleton<CameraLevelSensorService>(
    () => CameraLevelSensorService(),
  );
  sl.registerLazySingleton<FileNamingService>(() => FileNamingService());
  sl.registerLazySingleton<MediaShareService>(() => MediaShareService());
  sl.registerLazySingleton<MapLauncherService>(() => MapLauncherService());
  sl.registerLazySingleton<MediaThumbnailService>(
    () => MediaThumbnailService(),
  );

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
  sl.registerLazySingleton<LoginWithFacebook>(
    () => LoginWithFacebook(sl(), sl()),
  );
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
  sl.registerLazySingleton<UpdateUserProfile>(
    () => UpdateUserProfile(sl(), sl()),
  );
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
  sl.registerLazySingleton<SecurityEventLocalDataSource>(
    () => SecurityEventLocalDataSource(sl()),
  );
  sl.registerLazySingleton<ReportSecurityEvent>(
    () => ReportSecurityEvent(localDataSource: sl(), enqueueSyncItem: sl()),
  );
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
    () => ExpenseOcrRepositoryImpl(
      localDataSource: sl(),
      syncQueueLocalDataSource: sl(),
      timelineLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<ScanReceipt>(() => ScanReceipt(sl()));
  sl.registerLazySingleton<ConfirmAndSaveExpenseNote>(
    () => ConfirmAndSaveExpenseNote(repository: sl(), enqueueSyncItem: sl()),
  );
  sl.registerLazySingleton<SaveManualExpense>(() => SaveManualExpense(sl()));
  sl.registerLazySingleton<DeleteExpenseNote>(() => DeleteExpenseNote(sl()));
  sl.registerLazySingleton<UpdateExpenseNote>(() => UpdateExpenseNote(sl()));

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
      templateRepository: sl(),
      reportSecurityEvent: sl(),
    ),
  );
  sl.registerLazySingleton<CaptureGeotaggedPhoto>(
    () => CaptureGeotaggedPhoto(sl()),
  );
  sl.registerLazySingleton<CreateEvidence>(() => CreateEvidence(sl()));
  sl.registerLazySingleton<GetTaskPhotoPreviews>(
    () => GetTaskPhotoPreviews(sl()),
  );
  sl.registerLazySingleton<VerifyEvidenceIntegrity>(
    () => VerifyEvidenceIntegrity(hashGenerator: sl(), database: sl()),
  );
  sl.registerLazySingleton<GetActivityEvidence>(
    () => GetActivityEvidence(sl(), remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DeleteEvidence>(
    () =>
        DeleteEvidence(cameraLocalDataSource: sl(), syncLocalDataSource: sl()),
  );
  sl.registerLazySingleton<ShareEvidence>(() => ShareEvidence(sl()));

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
  sl.registerLazySingleton<GetTaskExpenses>(() => GetTaskExpenses(sl(), sl()));

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
  sl.registerLazySingleton<LanguageController>(
    () => LanguageController(localDataSource: sl()),
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

  // =====================================================================
  // PHASE 8: SMART ACTIVITY REPORT & LPJ FOUNDATION
  // =====================================================================
  sl.registerLazySingleton<ActivityReportLocalDataSource>(
    () => ActivityReportLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ActivityReportRemoteDataSource>(
    () => ActivityReportRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ReportDataAssembler>(
    () => ReportDataAssembler(
      cameraLocalDataSource: sl(),
      expenseLocalDataSource: sl(),
      timelineLocalDataSource: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerLazySingleton<ReportValidator>(() => ReportValidator());
  sl.registerLazySingleton<PdfReportGenerator>(() => PdfReportGenerator());

  sl.registerLazySingleton<ActivityReportRepository>(
    () => ActivityReportRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      assembler: sl(),
      validator: sl(),
      pdfGenerator: sl(),
      syncLocalDataSource: sl(),
      timelineLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<AssembleReportDraft>(
    () => AssembleReportDraft(sl()),
  );
  sl.registerLazySingleton<ValidateReportDraft>(
    () => ValidateReportDraft(sl()),
  );
  sl.registerLazySingleton<GenerateActivityReportPdf>(
    () => GenerateActivityReportPdf(sl()),
  );
  sl.registerLazySingleton<GetTaskReports>(() => GetTaskReports(sl()));
  sl.registerLazySingleton<DeleteActivityReport>(
    () => DeleteActivityReport(sl()),
  );
  sl.registerLazySingleton<VerifyReportSha256>(() => VerifyReportSha256(sl()));

  // =====================================================================
  // PHASE 9: PERJALANAN DINAS + SPPD + LPJ ENGINE
  // =====================================================================
  sl.registerLazySingleton<TravelLocalDatasource>(
    () => TravelLocalDatasource(),
  );
  sl.registerLazySingleton<TravelRemoteDatasource>(
    () => TravelRemoteDatasource(dioClient: sl()),
  );
  sl.registerLazySingleton<TravelCompletenessService>(
    () => TravelCompletenessService(),
  );
  sl.registerLazySingleton<TravelExpenseAggregator>(
    () => TravelExpenseAggregator(),
  );
  sl.registerLazySingleton<PdfLpjPackageGenerator>(
    () => PdfLpjPackageGenerator(),
  );

  sl.registerLazySingleton<TravelRepository>(
    () => TravelRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      completenessService: sl(),
      expenseAggregator: sl(),
      pdfGenerator: sl(),
      syncQueueRepository: sl(),
    ),
  );

  sl.registerLazySingleton<CreateTravelMission>(
    () => CreateTravelMission(sl()),
  );
  sl.registerLazySingleton<GetTravelMissions>(() => GetTravelMissions(sl()));
  sl.registerLazySingleton<GetTravelMissionDetail>(
    () => GetTravelMissionDetail(sl()),
  );
  sl.registerLazySingleton<AddSupportingDocument>(
    () => AddSupportingDocument(sl()),
  );
  sl.registerLazySingleton<GenerateLpjPackage>(() => GenerateLpjPackage(sl()));

  sl.registerFactory<TravelMissionListController>(
    () => TravelMissionListController(getTravelMissions: sl()),
  );
  sl.registerFactory<TravelMissionDetailController>(
    () => TravelMissionDetailController(
      getTravelMissionDetail: sl(),
      addSupportingDocument: sl(),
      generateLpjPackage: sl(),
      repository: sl(),
    ),
  );

  // =====================================================================
  // PHASE 10: SEARCH INTELLIGENCE & UNIFIED FIELD ARCHIVE
  // =====================================================================
  sl.registerLazySingleton<SearchLocalDatasource>(
    () => SearchLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<SearchRemoteDatasource>(
    () => SearchRemoteDatasourceImpl(client: sl()),
  );
  sl.registerLazySingleton<SearchQueryParser>(() => SearchQueryParser());
  sl.registerLazySingleton<SearchResultMerger>(() => SearchResultMerger());
  sl.registerLazySingleton<SearchIndexService>(() => SearchIndexService());
  sl.registerLazySingleton<SemanticSearchService>(
    () => SemanticSearchFoundationImpl(),
  );

  sl.registerLazySingleton<SearchArchiveRepository>(
    () => SearchArchiveRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      queryParser: sl(),
      merger: sl(),
      indexService: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<UnifiedSearch>(() => UnifiedSearch(sl()));
  sl.registerLazySingleton<GetRecentSearches>(() => GetRecentSearches(sl()));
  sl.registerLazySingleton<SaveRecentSearch>(() => SaveRecentSearch(sl()));
  sl.registerLazySingleton<ClearRecentSearches>(
    () => ClearRecentSearches(sl()),
  );
  sl.registerLazySingleton<RebuildSearchIndex>(() => RebuildSearchIndex(sl()));
  sl.registerLazySingleton<GetAvailableYears>(() => GetAvailableYears(sl()));

  sl.registerFactory<SearchArchiveController>(
    () => SearchArchiveController(
      unifiedSearch: sl(),
      getRecentSearches: sl(),
      saveRecentSearch: sl(),
      clearRecentSearches: sl(),
      rebuildSearchIndex: sl(),
      getAvailableYears: sl(),
    ),
  );

  // ============================================================
  // PHASE 11: DASHBOARD & FIELD INTELLIGENCE
  // ============================================================
  sl.registerLazySingleton<DashboardInsightEngine>(
    () => const DashboardInsightEngine(),
  );

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(insightEngine: sl()),
  );

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<GetDashboardAnalytics>(
    () => GetDashboardAnalytics(sl()),
  );

  // ============================================================
  // PHASE 12: SMART ASSISTANT & OPERATIONAL COPILOT ("TANYA TULAP")
  // ============================================================
  sl.registerLazySingleton<AssistantRemoteDataSource>(
    () => AssistantRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<AssistantLocalDataSource>(
    () => AssistantLocalDataSourceImpl(searchArchiveRepository: sl()),
  );

  sl.registerLazySingleton<AssistantRepository>(
    () => AssistantRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<AskAssistant>(() => AskAssistant(sl()));

  sl.registerLazySingleton<GetAssistantSuggestions>(
    () => GetAssistantSuggestions(sl()),
  );

  sl.registerFactory<AssistantController>(
    () =>
        AssistantController(askAssistant: sl(), getAssistantSuggestions: sl()),
  );

  // Tula: floating contextual assistant (redesign header AI -> global
  // overlay). Singleton karena dipasang sekali di root MaterialApp lewat
  // TulaOverlay dan status visibilitasnya (konteks layar, offline,
  // insight) harus konsisten di seluruh aplikasi.
  sl.registerLazySingleton<TulaPositionStore>(() => const TulaPositionStore());
  sl.registerLazySingleton<TulaVisibilityController>(
    () => TulaVisibilityController(sl(), sl()),
  );

  // ============================================================
  // SUBSCRIPTION - Halaman Paket Tulap (folder carousel). Sumber
  // kebenaran harga/benefit ada di PlanConfig; kuota kegiatan dihitung
  // sungguhan dari TaskRepository, bukan nilai rekaan.
  // ============================================================
  sl.registerLazySingleton<PlanRepository>(() => PlanRepositoryImpl());
  sl.registerLazySingleton<SubscriptionLocalDataSource>(
    () => SubscriptionLocalDataSource(),
  );
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      taskRepository: sl(),
      authSessionManager: sl(),
    ),
  );
  sl.registerLazySingleton<GetPlans>(() => GetPlans(sl()));
  sl.registerLazySingleton<GetCurrentSubscription>(
    () => GetCurrentSubscription(sl()),
  );
  sl.registerLazySingleton<GetSubscriptionUsage>(
    () => GetSubscriptionUsage(sl()),
  );
  sl.registerLazySingleton<SelectPlan>(() => SelectPlan(sl()));
  sl.registerLazySingleton<CheckActivityQuota>(() => CheckActivityQuota(sl()));

  // ============================================================
  // PEMBAYARAN (QRIS/VA) - lihat CheckoutController &
  // PaymentStatusController untuk orkestrasi UI. PaymentRepository
  // TIDAK punya local datasource/cache SENGAJA (Bagian 17 & 29 instruksi
  // payment - status pembayaran selalu dari backend).
  // ============================================================
  sl.registerLazySingleton<PaymentsRemoteDataSource>(
    () => PaymentsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CreateCheckout>(() => CreateCheckout(sl()));
  sl.registerLazySingleton<CheckPaymentStatus>(() => CheckPaymentStatus(sl()));
  sl.registerLazySingleton<GetPaymentHistory>(() => GetPaymentHistory(sl()));
  sl.registerLazySingleton<GetPaymentDetail>(() => GetPaymentDetail(sl()));
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
