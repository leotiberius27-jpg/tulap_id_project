import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/local_database.dart';
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

import '../../features/expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../features/expense_ocr/data/repositories/expense_ocr_repository_impl.dart';
import '../../features/expense_ocr/domain/repositories/expense_ocr_repository.dart';
import '../../features/expense_ocr/domain/usecases/save_expense_note.dart';
import '../../features/expense_ocr/domain/usecases/scan_receipt.dart';

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
import '../../features/task_detail/domain/usecases/get_task_detail.dart';
import '../../features/task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../features/task_detail/domain/usecases/toggle_checklist_item.dart';

/// Service locator global - dipanggil sebagai `sl<TipeClass>()` dari
/// mana pun di aplikasi setelah `initDependencies()` dijalankan.
final GetIt sl = GetIt.instance;

/// Ganti sesuai environment (dev/staging/production) - dalam proyek
/// nyata sebaiknya dibaca dari file .env, bukan hardcode di sini.
const String _kApiBaseUrl = 'https://api.tulap.id/v1';

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
    () => GeotagCameraLocalDataSource(hashGenerator: sl(), database: sl()),
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
  sl.registerLazySingleton<SubmitTaskForVerification>(
    () => SubmitTaskForVerification(sl()),
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
  if (sl.isRegistered<ValidateLocationIntegrity>()) {
    sl.unregister<ValidateLocationIntegrity>();
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
    ),
  );
  sl.registerLazySingleton<CaptureGeotaggedPhoto>(
    () => CaptureGeotaggedPhoto(sl()),
  );
  sl.registerLazySingleton<ValidateLocationIntegrity>(
    () => ValidateLocationIntegrity(
      mockLocationDetector: sl(),
      rootDetector: sl(),
    ),
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
  if (sl.isRegistered<ValidateLocationIntegrity>()) {
    sl.unregister<ValidateLocationIntegrity>();
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
