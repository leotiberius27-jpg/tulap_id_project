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
  });

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
