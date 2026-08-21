/// NotificationEntity
/// ----------------------------------------------------------------------
/// Selaras 1:1 dengan model `Notification` backend (Bagian 25 spesifikasi:
/// Notification System). Tidak ada logika bisnis tambahan di layer domain
/// ini - notifikasi murni ditampilkan seperti apa adanya dari server.
/// ----------------------------------------------------------------------
enum NotificationTypeEntity {
  taskAssigned,
  revisionNeeded,
  taskApproved,
  taskRejected,
  lpjReady,
  unknown,
}

class NotificationEntity {
  final String id;
  final NotificationTypeEntity type;
  final String title;
  final String body;
  final String? relatedTaskId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.relatedTaskId,
  });

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      body: body,
      relatedTaskId: relatedTaskId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
