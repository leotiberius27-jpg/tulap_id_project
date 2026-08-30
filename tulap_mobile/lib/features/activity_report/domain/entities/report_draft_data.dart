import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/entities/activity_note_entity.dart';
import '../../../task_detail/domain/entities/timeline_event_entity.dart';
import 'report_template_entity.dart';

/// ReportDraftData
/// ----------------------------------------------------------------------
/// Kumpulan data terstruktur hasil assemblasi dari rekam kegiatan lapangan
/// sebelum dikonversi menjadi dokumen PDF resmi.
/// Memungkinkan user meninjau, mengedit narasi, memilih & mengurutkan foto,
/// serta menyesuaikan lampiran tanpa mengetik ulang data yang sudah ada.
/// ----------------------------------------------------------------------
class ReportDraftData {
  final TaskEntity task;
  final AuthUserEntity? user;
  final String title;
  final String narrative;
  final List<GeotagPhotoEntity> selectedEvidence;
  final List<ExpenseNoteEntity> selectedExpenses;
  final List<TimelineEventEntity> selectedTimelineEvents;
  final List<ActivityNoteEntity> selectedNotes;
  final ReportTemplateEntity template;
  final String? supervisorName;
  final String? supervisorTitle;
  final String? implementerName;
  final String? implementerTitle;
  final DateTime assembledAt;

  const ReportDraftData({
    required this.task,
    this.user,
    required this.title,
    required this.narrative,
    required this.selectedEvidence,
    required this.selectedExpenses,
    required this.selectedTimelineEvents,
    required this.selectedNotes,
    this.template = ReportTemplateEntity.defaultActivity,
    this.supervisorName,
    this.supervisorTitle,
    this.implementerName,
    this.implementerTitle,
    required this.assembledAt,
  });

  /// Menghitung ulang total pengeluaran dari data numerik otoritatif
  double get totalExpenseSum {
    return selectedExpenses.fold<double>(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );
  }

  int get photoCount => selectedEvidence.where((e) => !e.isVideo).length;
  int get videoCount => selectedEvidence.where((e) => e.isVideo).length;
  int get receiptCount => selectedExpenses.length;

  ReportDraftData copyWith({
    TaskEntity? task,
    AuthUserEntity? user,
    String? title,
    String? narrative,
    List<GeotagPhotoEntity>? selectedEvidence,
    List<ExpenseNoteEntity>? selectedExpenses,
    List<TimelineEventEntity>? selectedTimelineEvents,
    List<ActivityNoteEntity>? selectedNotes,
    ReportTemplateEntity? template,
    String? supervisorName,
    String? supervisorTitle,
    String? implementerName,
    String? implementerTitle,
    DateTime? assembledAt,
  }) {
    return ReportDraftData(
      task: task ?? this.task,
      user: user ?? this.user,
      title: title ?? this.title,
      narrative: narrative ?? this.narrative,
      selectedEvidence: selectedEvidence ?? this.selectedEvidence,
      selectedExpenses: selectedExpenses ?? this.selectedExpenses,
      selectedTimelineEvents: selectedTimelineEvents ?? this.selectedTimelineEvents,
      selectedNotes: selectedNotes ?? this.selectedNotes,
      template: template ?? this.template,
      supervisorName: supervisorName ?? this.supervisorName,
      supervisorTitle: supervisorTitle ?? this.supervisorTitle,
      implementerName: implementerName ?? this.implementerName,
      implementerTitle: implementerTitle ?? this.implementerTitle,
      assembledAt: assembledAt ?? this.assembledAt,
    );
  }
}
