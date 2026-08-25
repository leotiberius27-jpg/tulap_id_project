/// NotificationCategory
/// ----------------------------------------------------------------------
/// Kategori utama filter di NotificationCenterPage:
/// - Semua (semua kategori)
/// - Kegiatan (tugas, aktivitas, checklist)
/// - Sinkronisasi (outbox, upload foto, status cloud)
/// - Sistem (akun, biometrik, izin, peringatan lokasi)
/// ----------------------------------------------------------------------
enum NotificationCategory {
  kegiatan,
  sinkronisasi,
  sistem;

  String get label {
    switch (this) {
      case NotificationCategory.kegiatan:
        return 'Kegiatan';
      case NotificationCategory.sinkronisasi:
        return 'Sinkronisasi';
      case NotificationCategory.sistem:
        return 'Sistem';
    }
  }

  static NotificationCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'kegiatan':
      case 'activity':
        return NotificationCategory.kegiatan;
      case 'sinkronisasi':
      case 'sync':
        return NotificationCategory.sinkronisasi;
      case 'sistem':
      case 'system':
      default:
        return NotificationCategory.sistem;
    }
  }
}

/// NotificationType
/// ----------------------------------------------------------------------
/// Tipe spesifik notifikasi operasional lapangan Tulap.id
/// ----------------------------------------------------------------------
enum NotificationType {
  activityRunning,
  activityIncomplete,
  activityCompleted,
  syncPending,
  syncFailed,
  syncCompleted,
  receiptProcessed,
  receiptReviewRequired,
  locationPermissionRequired,
  locationAccuracyWarning,
  systemInfo,
  securityInfo;

  static NotificationType fromString(String val) {
    for (final t in NotificationType.values) {
      if (t.name == val) return t;
    }
    return NotificationType.systemInfo;
  }
}

/// NotificationPriority
/// ----------------------------------------------------------------------
/// Tingkat urgensi notifikasi (menentukan warna aksen & icon)
/// ----------------------------------------------------------------------
enum NotificationPriority {
  info,
  success,
  warning,
  error;

  static NotificationPriority fromString(String val) {
    switch (val.toLowerCase()) {
      case 'success':
        return NotificationPriority.success;
      case 'warning':
        return NotificationPriority.warning;
      case 'error':
      case 'danger':
        return NotificationPriority.error;
      case 'info':
      default:
        return NotificationPriority.info;
    }
  }
}

/// NotificationActionType
/// ----------------------------------------------------------------------
/// Tindakan deep-link saat notifikasi diketuk
/// ----------------------------------------------------------------------
enum NotificationActionType {
  openTask,
  openSync,
  openReceipt,
  openLocation,
  none;

  static NotificationActionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'opentask':
      case 'open_task':
        return NotificationActionType.openTask;
      case 'opensync':
      case 'open_sync':
        return NotificationActionType.openSync;
      case 'openreceipt':
      case 'open_receipt':
        return NotificationActionType.openReceipt;
      case 'openlocation':
      case 'open_location':
        return NotificationActionType.openLocation;
      case 'none':
      default:
        return NotificationActionType.none;
    }
  }
}

/// NotificationEntity (AppNotificationEntity)
/// ----------------------------------------------------------------------
/// Entitas notifikasi operasional lapangan Tulap.id
/// Bersifat offline-first dan terikat dengan user ID terautentikasi.
/// ----------------------------------------------------------------------
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationCategory category;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final NotificationActionType actionType;
  final String? actionPayload;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.category,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityType,
    this.relatedEntityId,
    this.actionType = NotificationActionType.none,
    this.actionPayload,
    this.priority = NotificationPriority.info,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Backwards compatibility getters
  String get body => message;
  String? get relatedTaskId =>
      relatedEntityType == 'TASK' || actionType == NotificationActionType.openTask
          ? relatedEntityId
          : null;

  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationCategory? category,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedEntityType,
    String? relatedEntityId,
    NotificationActionType? actionType,
    String? actionPayload,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      actionType: actionType ?? this.actionType,
      actionPayload: actionPayload ?? this.actionPayload,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
