/// TaskStatusEntity
/// ----------------------------------------------------------------------
/// Selaras 1:1 dengan enum TaskStatus di skema Prisma backend.
/// ----------------------------------------------------------------------
enum TaskStatusEntity {
  draft,
  ongoing,
  pendingVerification,
  revisionNeeded,
  verified,
  rejected,
  completed,
}

/// Status akhir yang tidak lagi butuh tindakan pegawai - dipakai untuk
/// memisahkan tab "Tugas" (aktif/butuh tindakan) dari "Riwayat" (sudah
/// tuntas), lihat TaskListController & HistoryController. Satu sumber
/// kebenaran agar definisi "selesai" tidak drift antara kedua tab.
extension TaskStatusEntityX on TaskStatusEntity {
  bool get isFinal =>
      this == TaskStatusEntity.verified ||
      this == TaskStatusEntity.rejected ||
      this == TaskStatusEntity.completed;
}

class ChecklistItemEntity {
  final String id;
  final String taskId;
  final String label;
  final int order;
  final bool isMandatory;
  final bool isCompleted;

  const ChecklistItemEntity({
    required this.id,
    required this.taskId,
    required this.label,
    required this.order,
    required this.isMandatory,
    required this.isCompleted,
  });

  ChecklistItemEntity copyWith({bool? isCompleted}) {
    return ChecklistItemEntity(
      id: id,
      taskId: taskId,
      label: label,
      order: order,
      isMandatory: isMandatory,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// TaskEntity
/// ----------------------------------------------------------------------
/// Representasi murni satu tugas SPPD di layer domain. Field selaras
/// dengan tabel `Task_SPPD` di skema Prisma backend.
/// ----------------------------------------------------------------------
class TaskEntity {
  final String id;
  final String taskCode;
  final String taskName;
  final String destination;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final double budgetAmount;
  final TaskStatusEntity status;
  final String assigneeId;
  final String assigneeName;

  final List<ChecklistItemEntity> checklistItems;
  final int geotagPhotoCount;
  final int expenseNoteCount;

  /// Catatan Verifikator paling baru saat status revisionNeeded/rejected
  /// (Bagian 22 spesifikasi: "Nota BBM - Nominal kurang jelas") - null
  /// untuk status lain, atau untuk data lama dari cache lokal sebelum
  /// field ini ada.
  final String? latestRevisionNote;

  final bool isSelfCreated;
  final String syncStatus;
  final int syncVersion;

  /// Kaitan ke Perjalanan Dinas (opsional jika aktivitas berdiri sendiri)
  final String? travelId;

  /// Timestamp pencatatan waktu kegiatan di lapangan (offline/cloud-aware)
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskEntity({
    required this.id,
    required this.taskCode,
    required this.taskName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budgetAmount,
    required this.status,
    required this.assigneeId,
    required this.assigneeName,
    required this.checklistItems,
    required this.geotagPhotoCount,
    required this.expenseNoteCount,
    this.description,
    this.latestRevisionNote,
    this.isSelfCreated = false,
    this.syncStatus = 'SYNCED',
    this.syncVersion = 1,
    this.travelId,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// True jika kegiatan berlangsung lebih dari 1 hari kalender
  bool get isMultiDay =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  /// Dipakai TaskRepositoryImpl untuk menempelkan `latestRevisionNote`
  /// dari hasil fetch server ke atas entity hasil gabungan cache lokal
  TaskEntity withLatestRevisionNote(String? note) {
    return TaskEntity(
      id: id,
      taskCode: taskCode,
      taskName: taskName,
      destination: destination,
      description: description,
      startDate: startDate,
      endDate: endDate,
      budgetAmount: budgetAmount,
      status: status,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      checklistItems: checklistItems,
      geotagPhotoCount: geotagPhotoCount,
      expenseNoteCount: expenseNoteCount,
      latestRevisionNote: note,
      isSelfCreated: isSelfCreated,
      syncStatus: syncStatus,
      syncVersion: syncVersion,
      travelId: travelId,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  TaskEntity copyWith({
    String? id,
    String? taskCode,
    String? taskName,
    String? destination,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budgetAmount,
    TaskStatusEntity? status,
    String? assigneeId,
    String? assigneeName,
    List<ChecklistItemEntity>? checklistItems,
    int? geotagPhotoCount,
    int? expenseNoteCount,
    String? latestRevisionNote,
    bool? isSelfCreated,
    String? syncStatus,
    int? syncVersion,
    String? travelId,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      taskCode: taskCode ?? this.taskCode,
      taskName: taskName ?? this.taskName,
      destination: destination ?? this.destination,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      checklistItems: checklistItems ?? this.checklistItems,
      geotagPhotoCount: geotagPhotoCount ?? this.geotagPhotoCount,
      expenseNoteCount: expenseNoteCount ?? this.expenseNoteCount,
      latestRevisionNote: latestRevisionNote ?? this.latestRevisionNote,
      isSelfCreated: isSelfCreated ?? this.isSelfCreated,
      syncStatus: syncStatus ?? this.syncStatus,
      syncVersion: syncVersion ?? this.syncVersion,
      travelId: travelId ?? this.travelId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedChecklistCount =>
      checklistItems.where((i) => i.isCompleted).length;

  List<ChecklistItemEntity> get incompleteMandatoryItems =>
      checklistItems.where((i) => i.isMandatory && !i.isCompleted).toList();

  /// Sesuai Bagian 7 spesifikasi: "1 bukti wajib belum lengkap." -
  /// dipakai UI untuk menentukan apakah tombol "Kirim Tugas" aktif
  /// atau CTA sekunder "Lengkapi Bukti" yang harus ditampilkan.
  bool get isReadyToSubmit => incompleteMandatoryItems.isEmpty;

  double get checklistProgress => checklistItems.isEmpty
      ? 0
      : completedChecklistCount / checklistItems.length;
}
