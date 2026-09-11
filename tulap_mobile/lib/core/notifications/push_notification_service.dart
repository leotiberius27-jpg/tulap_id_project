import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/di/injection_container.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/task_detail/domain/usecases/get_task_detail.dart';
import '../../features/task_detail/domain/usecases/start_task.dart';
import '../../features/task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../features/task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../features/task_detail/presentation/controllers/task_detail_controller.dart';
import '../../features/task_detail/presentation/pages/task_detail_page.dart';
import '../session/auth_session_manager.dart';

/// _firebaseMessagingBackgroundHandler
/// ----------------------------------------------------------------------
/// WAJIB top-level function (bukan method kelas) - dijalankan Android di
/// isolate terpisah saat app di-background/terminated. Sistem Android
/// SUDAH menampilkan notifikasi tray secara otomatis dari field
/// `notification` payload FCM tanpa kode ini (dikonfirmasi lewat
/// dokumentasi resmi) - handler ini murni tempat menaruh pemrosesan data
/// tambahan di masa depan bila diperlukan, no-op untuk sekarang.
/// ----------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// PushNotificationService
/// ----------------------------------------------------------------------
/// Menjembatani Firebase Cloud Messaging dengan sesi login user (Bagian
/// 25 dokumen spesifikasi: Notification System - kini juga lewat push,
/// bukan cuma polling saat app dibuka):
///   - Sesi TERBENTUK (login baru ATAU sesi lama dipulihkan saat app
///     dibuka) -> minta izin notifikasi + daftarkan token FCM perangkat
///     ke backend (POST /notifications/device-token).
///   - Token FCM berubah (rotasi berkala Firebase) -> daftarkan ulang
///     selama sesi masih aktif.
///   - LOGOUT -> hapus token itu dari backend (DELETE
///     /notifications/device-token), supaya device yang sudah logout
///     tidak lagi menerima push untuk akun itu.
///   - Pesan tiba saat app FOREGROUND -> refresh NotificationsRepository
///     (bukan generate entry lokal terpisah dari payload) supaya
///     backend tetap satu-satunya sumber kebenaran.
///   - Notifikasi DIKETUK (background/terminated) -> buka TaskDetailPage
///     untuk `relatedTaskId` di payload data - SELURUH tipe notifikasi
///     backend saat ini (TASK_ASSIGNED/REVISION_NEEDED/TASK_APPROVED/
///     TASK_REJECTED/LPJ_READY) menyertakan field ini.
///
/// Kegagalan di manapun dalam alur ini (izin ditolak, token gagal
/// diambil, request registrasi gagal) TIDAK PERNAH boleh mengganggu
/// alur login/logout - push notification murni best-effort/opsional.
/// ----------------------------------------------------------------------
class PushNotificationService {
  final AuthSessionManager _authSessionManager;
  final NotificationsRemoteDataSource _remoteDataSource;
  final NotificationsRepository _notificationsRepository;
  final GlobalKey<NavigatorState> _navigatorKey;

  bool _wasAuthenticated = false;
  String? _lastRegisteredToken;
  StreamSubscription<String>? _tokenRefreshSub;

  PushNotificationService({
    required AuthSessionManager authSessionManager,
    required NotificationsRemoteDataSource remoteDataSource,
    required NotificationsRepository notificationsRepository,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _authSessionManager = authSessionManager,
        _remoteDataSource = remoteDataSource,
        _notificationsRepository = notificationsRepository,
        _navigatorKey = navigatorKey;

  Future<void> init() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (_authSessionManager.isAuthenticated) {
        _registerToken(token);
      }
    });

    _authSessionManager.addListener(_onAuthChanged);
    // Evaluasi state awal - sesi lama mungkin sudah dipulihkan sebelum
    // listener ini terpasang.
    _onAuthChanged();
  }

  void dispose() {
    _authSessionManager.removeListener(_onAuthChanged);
    _tokenRefreshSub?.cancel();
  }

  void _onAuthChanged() {
    final isAuthenticated = _authSessionManager.isAuthenticated;
    if (isAuthenticated && !_wasAuthenticated) {
      _requestPermissionAndRegister();
    } else if (!isAuthenticated && _wasAuthenticated) {
      _unregisterCurrentToken();
    }
    _wasAuthenticated = isAuthenticated;
  }

  Future<void> _requestPermissionAndRegister() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (_) {
      // Opsional - kegagalan minta izin/ambil token TIDAK PERNAH boleh
      // mengganggu alur login.
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _remoteDataSource.registerDeviceToken(token);
      _lastRegisteredToken = token;
    } catch (_) {
      // Best-effort - percobaan berikutnya terjadi lewat onTokenRefresh
      // atau saat sesi berikutnya terbentuk.
    }
  }

  Future<void> _unregisterCurrentToken() async {
    final token = _lastRegisteredToken;
    if (token == null) return;
    _lastRegisteredToken = null;
    try {
      await _remoteDataSource.unregisterDeviceToken(token);
    } catch (_) {
      // Best-effort - token toh akan diambil-alih backend (upsert by
      // token) kalau akun lain login di perangkat yang sama.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Refresh daftar+badge notifikasi dari backend - satu-satunya sumber
    // kebenaran, bukan membangun entry lokal terpisah dari payload FCM.
    _notificationsRepository.getNotifications();
  }

  void _handleNotificationTap(RemoteMessage message) {
    final taskId = message.data['relatedTaskId'] as String?;
    if (taskId == null || taskId.isEmpty) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final user = _authSessionManager.currentUser;
    final officerName =
        (user != null && user.fullName.trim().isNotEmpty && !user.fullName.contains('@'))
            ? user.fullName.trim()
            : 'Pengguna';
    final agencyName = user?.instansiName ?? '';

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskDetailController>(
          create: (_) => TaskDetailController(
            getTaskDetail: sl<GetTaskDetail>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            startTask: sl<StartTask>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
            taskId: taskId,
          ),
          child: TaskDetailPage(
            officerName: officerName,
            agencyName: agencyName,
          ),
        ),
      ),
    );
  }
}
