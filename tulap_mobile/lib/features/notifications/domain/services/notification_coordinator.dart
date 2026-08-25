import 'package:uuid/uuid.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/create_or_update_notification.dart';

class NotificationCoordinator {
  final CreateOrUpdateNotification _createOrUpdateNotification;
  final NotificationsRepository _notificationsRepository;
  final AuthSessionManager? _authSessionManager;
  final Uuid _uuid = const Uuid();

  NotificationCoordinator({
    required CreateOrUpdateNotification createOrUpdateNotification,
    required NotificationsRepository notificationsRepository,
    AuthSessionManager? authSessionManager,
  })  : _createOrUpdateNotification = createOrUpdateNotification,
        _notificationsRepository = notificationsRepository,
        _authSessionManager = authSessionManager;

  String get _currentUserId =>
      _authSessionManager?.currentUser?.id ?? 'current_user';

  /// 1. SINKRONISASI / OUTBOX QUEUE TRIGGER
  Future<void> evaluateSyncQueue({
    required int pendingCount,
    required int failedCount,
    required int syncedCount,
  }) async {
    final userId = _currentUserId;

    if (failedCount > 0) {
      await _createOrUpdateNotification(
        NotificationEntity(
          id: 'sync_failed_$userId',
          userId: userId,
          category: NotificationCategory.sinkronisasi,
          type: NotificationType.syncFailed,
          title: 'Sinkronisasi gagal',
          message:
              '$failedCount dokumentasi gagal diunggah ke cloud. Ketuk untuk mencoba lagi.',
          relatedEntityType: 'SYNC',
          actionType: NotificationActionType.openSync,
          priority: NotificationPriority.error,
          createdAt: DateTime.now(),
        ),
      );
    } else if (pendingCount > 0) {
      await _createOrUpdateNotification(
        NotificationEntity(
          id: 'sync_pending_$userId',
          userId: userId,
          category: NotificationCategory.sinkronisasi,
          type: NotificationType.syncPending,
          title: 'Data belum tersinkronisasi',
          message:
              '$pendingCount dokumentasi menunggu dikirim ke cloud saat online.',
          relatedEntityType: 'SYNC',
          actionType: NotificationActionType.openSync,
          priority: NotificationPriority.warning,
          createdAt: DateTime.now(),
        ),
      );
    } else if (syncedCount > 0) {
      // Hapus notifikasi pending jika semua sudah tersinkronisasi
      await _notificationsRepository.deleteNotification('sync_pending_$userId');
      await _notificationsRepository.deleteNotification('sync_failed_$userId');

      await _createOrUpdateNotification(
        NotificationEntity(
          id: 'sync_completed_$userId',
          userId: userId,
          category: NotificationCategory.sinkronisasi,
          type: NotificationType.syncCompleted,
          title: 'Semua data tersinkronisasi',
          message: '$syncedCount dokumentasi berhasil disimpan ke cloud.',
          relatedEntityType: 'SYNC',
          actionType: NotificationActionType.openSync,
          priority: NotificationPriority.success,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// 2. KEGIATAN AKTIF & SELESAI
  Future<void> notifyActiveTask({
    required String taskId,
    required String taskName,
    required int completedChecklists,
    required int totalChecklists,
  }) async {
    final userId = _currentUserId;
    await _createOrUpdateNotification(
      NotificationEntity(
        id: 'task_running_$taskId',
        userId: userId,
        category: NotificationCategory.kegiatan,
        type: NotificationType.activityRunning,
        title: 'Kegiatan sedang berjalan',
        message:
            '$taskName masih aktif. $completedChecklists dari $totalChecklists checklist selesai.',
        relatedEntityType: 'TASK',
        relatedEntityId: taskId,
        actionType: NotificationActionType.openTask,
        priority: NotificationPriority.info,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyTaskCompleted({
    required String taskId,
    required String taskName,
  }) async {
    final userId = _currentUserId;
    // Bersihkan notifikasi running task
    await _notificationsRepository.deleteNotification('task_running_$taskId');

    await _createOrUpdateNotification(
      NotificationEntity(
        id: 'task_completed_$taskId',
        userId: userId,
        category: NotificationCategory.kegiatan,
        type: NotificationType.activityCompleted,
        title: 'Kegiatan selesai',
        message: '$taskName telah selesai dan masuk ke Riwayat.',
        relatedEntityType: 'TASK',
        relatedEntityId: taskId,
        actionType: NotificationActionType.openTask,
        priority: NotificationPriority.success,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 3. NOTA & EXPENSE OCR
  Future<void> notifyReceiptProcessed({
    required String taskName,
    required String taskId,
    required double totalAmount,
    String? vendorName,
  }) async {
    final userId = _currentUserId;
    final formattedAmount = 'Rp${totalAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';

    await _createOrUpdateNotification(
      NotificationEntity(
        id: _uuid.v4(),
        userId: userId,
        category: NotificationCategory.kegiatan,
        type: NotificationType.receiptProcessed,
        title: 'Nota berhasil diproses',
        message:
            'Nota $formattedAmount${vendorName != null ? " ($vendorName)" : ""} telah ditambahkan ke $taskName.',
        relatedEntityType: 'TASK',
        relatedEntityId: taskId,
        actionType: NotificationActionType.openTask,
        priority: NotificationPriority.success,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 4. LOKASI & GPS WARNING
  Future<void> notifyLocationWarning({
    required bool isPermissionDenied,
    required String message,
  }) async {
    final userId = _currentUserId;
    await _createOrUpdateNotification(
      NotificationEntity(
        id: 'location_warning_$userId',
        userId: userId,
        category: NotificationCategory.sistem,
        type: isPermissionDenied
            ? NotificationType.locationPermissionRequired
            : NotificationType.locationAccuracyWarning,
        title: isPermissionDenied ? 'Izin lokasi diperlukan' : 'GPS kurang akurat',
        message: message,
        relatedEntityType: 'LOCATION',
        actionType: NotificationActionType.openLocation,
        priority: NotificationPriority.warning,
        createdAt: DateTime.now(),
      ),
    );
  }
}
