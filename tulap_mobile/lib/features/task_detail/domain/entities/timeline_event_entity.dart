/// TimelineEventType
/// ----------------------------------------------------------------------
/// Kategori kejadian penting yang direkam otomatis di linimasa kegiatan.
/// ----------------------------------------------------------------------
enum TimelineEventType {
  activityCreated,
  activityStarted,
  locationRecorded,
  photoCaptured,
  receiptScanned,
  expenseRecorded,
  checklistToggled,
  noteAdded,
  activityCompleted,
  syncCompleted;

  String get label {
    switch (this) {
      case TimelineEventType.activityCreated:
        return 'Kegiatan Dibuat';
      case TimelineEventType.activityStarted:
        return 'Kegiatan Dimulai';
      case TimelineEventType.locationRecorded:
        return 'Lokasi Direkam';
      case TimelineEventType.photoCaptured:
        return 'Dokumentasi Foto';
      case TimelineEventType.receiptScanned:
        return 'Nota Dipindai';
      case TimelineEventType.expenseRecorded:
        return 'Pengeluaran Dicatat';
      case TimelineEventType.checklistToggled:
        return 'Checklist Diperbarui';
      case TimelineEventType.noteAdded:
        return 'Catatan Ditambahkan';
      case TimelineEventType.activityCompleted:
        return 'Kegiatan Selesai';
      case TimelineEventType.syncCompleted:
        return 'Sinkronisasi Cloud';
    }
  }

  static TimelineEventType fromString(String val) {
    for (final t in TimelineEventType.values) {
      if (t.name == val) return t;
    }
    return TimelineEventType.noteAdded;
  }
}

/// TimelineEventEntity
/// ----------------------------------------------------------------------
/// Representasi domain satu butir kejadian di linimasa kegiatan.
/// ----------------------------------------------------------------------
class TimelineEventEntity {
  final String id;
  final String taskId;
  final TimelineEventType eventType;
  final String title;
  final String? description;
  final DateTime eventTimestamp;
  final Map<String, dynamic>? metadata;
  final String syncStatus;

  const TimelineEventEntity({
    required this.id,
    required this.taskId,
    required this.eventType,
    required this.title,
    this.description,
    required this.eventTimestamp,
    this.metadata,
    this.syncStatus = 'LOCAL_ONLY',
  });

  TimelineEventEntity copyWith({
    String? id,
    String? taskId,
    TimelineEventType? eventType,
    String? title,
    String? description,
    DateTime? eventTimestamp,
    Map<String, dynamic>? metadata,
    String? syncStatus,
  }) {
    return TimelineEventEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      description: description ?? this.description,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      metadata: metadata ?? this.metadata,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
