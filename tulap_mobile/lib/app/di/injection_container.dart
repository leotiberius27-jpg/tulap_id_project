import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
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
import '../../core/sync/background_sync_service.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_session.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';

import '../../features/expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../features/expense_ocr/data/repositories/expense_ocr_repository_impl.dart';
import '../../features/expense_ocr/domain/repositories/expense_ocr_repository.dart';
import '../../features/expense_ocr/domain/usecases/save_expense_note.dart';
import '../../features/expense_ocr/domain/usecases/scan_receipt.dart';

import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';

import '../../features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../features/geotag_camera/data/repositories/geotag_camera_repository_impl.dart';
import '../../features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import '../../features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import '../../features/geotag_camera/domain/usecases/validate_location_integrity.dart';

import '../../features/sync_queue/data/datasources/sync_local_datasource.dart';
import '../../features/sync_queue/data/datasources/sync_remote_datasource.dart';
import '../../features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import '../../features/sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../features/sync_queue/domain/usecases/enqueue_sync_item.dart';
import '../../features/sync_queue/domain/usecases/process_sync_queue.dart';

import '../../features/task_detail/data/datasources/task_local_datasource.dart';
import '../../features/task_detail/data/datasources/task_remote_datasource.dart';
import '../../features/task_detail/data/repositories/task_repository_impl.dart';
import '../../features/task_detail/domain/repositories/task_repository.dart';
import '../../features/task_detail/domain/usecases/get_active_tasks.dart';
import '../../features/task_detail/domain/usecases/get_task_detail.dart';
import '../../features/task_detail/domain/usecases/pick_active_task.dart';
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
  defaultValue: 'http://10.0.2.2:3000',
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
Future<void> initDependencies() async {
  // ============================================================
  // CORE - Database, Network, Security, OCR
  // ============================================================
  final Database database = await LocalDatabase.instance;
  sl.registerSingleton<Database>(database);

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(sl()));
  sl.registerLazySingleton<DioClient>(
    () => DioClient(baseUrl: _kApiBaseUrl),
  );

  sl.registerLazySingleton<MockLocationDetector>(() => MockLocationDetector());
  sl.registerLazySingleton<RootDetector>(() => RootDetector());
  sl.registerLazySingleton<HashGenerator>(() => HashGenerator());
  sl.registerLazySingleton<PlusCodeGenerator>(() => PlusCodeGenerator());
  sl.registerLazySingleton<ReverseGeocoder>(() => ReverseGeocoder());
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
  sl.registerLazySingleton<Login>(() => Login(sl()));
  sl.registerLazySingleton<GetCurrentSession>(() => GetCurrentSession(sl()));
  sl.registerLazySingleton<Logout>(() => Logout(sl()));

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
  // nya BUTUH CameraController, jadi didaftarkan lewat
  // `registerScannerSession` (lihat di bawah), bukan di sini.
  // ============================================================
  sl.registerLazySingleton<ExpenseOcrLocalDataSource>(
    () => ExpenseOcrLocalDataSource(ocrEngine: sl(), parser: sl(), database: sl()),
  );

  // ============================================================
  // GEOTAG CAMERA - sama seperti expense_ocr, datasource lokal
  // didaftarkan di sini, repository menyusul saat sesi kamera dibuka.
  // ============================================================
  sl.registerLazySingleton<GeotagCameraLocalDataSource>(
    () => GeotagCameraLocalDataSource(
      hashGenerator: sl(),
      watermarkCompositor: sl(),
      database: sl(),
    ),
  );

  // ============================================================
  // TASK DETAIL - tidak bergantung pada CameraController, jadi
  // seluruhnya bisa didaftarkan sebagai singleton global di sini.
  // ============================================================
  sl.registerLazySingleton<TaskLocalDataSource>(() => TaskLocalDataSource(sl()));
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSource(sl()));
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      enqueueSyncItem: sl(),
    ),
  );
  sl.registerLazySingleton<GetTaskDetail>(() => GetTaskDetail(sl()));
  sl.registerLazySingleton<ToggleChecklistItem>(() => ToggleChecklistItem(sl()));
  sl.registerLazySingleton<StartTask>(() => StartTask(sl()));
  sl.registerLazySingleton<SubmitTaskForVerification>(
    () => SubmitTaskForVerification(sl()),
  );
  sl.registerLazySingleton<GetActiveTasks>(() => GetActiveTasks(sl()));
  sl.registerLazySingleton<PickActiveTask>(() => PickActiveTask(sl()));

  // ============================================================
  // NOTIFICATIONS - murni baca dari server, tidak ada dependency
  // lain di luar DioClient, jadi seluruhnya global di sini.
  // ============================================================
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<GetNotifications>(() => GetNotifications(sl()));
  sl.registerLazySingleton<MarkNotificationRead>(() => MarkNotificationRead(sl()));
  sl.registerLazySingleton<MarkAllNotificationsRead>(
    () => MarkAllNotificationsRead(sl()),
  );

  // ============================================================
  // LOCATION - ValidateLocationIntegrity TIDAK bergantung pada
  // CameraController (hanya butuh MockLocationDetector & RootDetector,
  // keduanya sudah singleton di atas), jadi didaftarkan global di sini
  // agar tab "Lokasi" bisa dipakai TANPA harus membuka kamera dulu -
  // sebelumnya usecase ini keliru dikelompokkan sebagai bagian dari
  // sesi kamera (lihat registerCameraSession), padahal cuma numpang
  // lewat karena secara historis dipakai dari layar kamera.
  // ============================================================
  sl.registerLazySingleton<ValidateLocationIntegrity>(
    () => ValidateLocationIntegrity(
      mockLocationDetector: sl(),
      rootDetector: sl(),
    ),
  );
}

/// registerCameraSession
/// ----------------------------------------------------------------------
/// Dipanggil dari `initState()` GeotagCameraPage/ReceiptScannerPage
/// SETELAH `CameraController` berhasil diinisialisasi. Mendaftarkan
/// repository & usecase yang bergantung pada controller tsb sebagai
/// factory baru untuk sesi kamera kali ini.
///
/// PENTING: panggil `unregisterCameraSession()` di `dispose()` halaman
/// terkait untuk melepas CameraController lama dari service locator -
/// mencegah memory leak & referensi ke controller yang sudah di-dispose.
/// ----------------------------------------------------------------------
void registerCameraSession(CameraController controller) {
  if (sl.isRegistered<GeotagCameraRepository>()) {
    sl.unregister<GeotagCameraRepository>();
  }
  if (sl.isRegistered<CaptureGeotaggedPhoto>()) {
    sl.unregister<CaptureGeotaggedPhoto>();
  }
  if (sl.isRegistered<ExpenseOcrRepository>()) {
    sl.unregister<ExpenseOcrRepository>();
  }
  if (sl.isRegistered<ScanReceipt>()) {
    sl.unregister<ScanReceipt>();
  }
  if (sl.isRegistered<ConfirmAndSaveExpenseNote>()) {
    sl.unregister<ConfirmAndSaveExpenseNote>();
  }

  sl.registerLazySingleton<GeotagCameraRepository>(
    () => GeotagCameraRepositoryImpl(
      localDataSource: sl(),
      mockLocationDetector: sl(),
      rootDetector: sl(),
      cameraController: controller,
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

  sl.registerLazySingleton<ExpenseOcrRepository>(
    () => ExpenseOcrRepositoryImpl(localDataSource: sl(), cameraController: controller),
  );
  sl.registerLazySingleton<ScanReceipt>(() => ScanReceipt(sl()));
  sl.registerLazySingleton<ConfirmAndSaveExpenseNote>(
    () => ConfirmAndSaveExpenseNote(repository: sl(), enqueueSyncItem: sl()),
  );
}

/// Dipanggil dari `dispose()` halaman kamera untuk melepas registrasi
/// yang bergantung pada CameraController sesi tsb.
void unregisterCameraSession() {
  if (sl.isRegistered<GeotagCameraRepository>()) {
    sl.unregister<GeotagCameraRepository>();
  }
  if (sl.isRegistered<CaptureGeotaggedPhoto>()) {
    sl.unregister<CaptureGeotaggedPhoto>();
  }
  if (sl.isRegistered<ExpenseOcrRepository>()) {
    sl.unregister<ExpenseOcrRepository>();
  }
  if (sl.isRegistered<ScanReceipt>()) {
    sl.unregister<ScanReceipt>();
  }
  if (sl.isRegistered<ConfirmAndSaveExpenseNote>()) {
    sl.unregister<ConfirmAndSaveExpenseNote>();
  }
}
