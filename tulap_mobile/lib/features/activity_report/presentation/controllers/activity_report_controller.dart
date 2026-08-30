import 'package:flutter/foundation.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/activity_report_entity.dart';
import '../../domain/entities/report_draft_data.dart';
import '../../domain/entities/report_template_entity.dart';
import '../../domain/entities/report_validation_result.dart';
import '../../domain/usecases/assemble_report_draft.dart';
import '../../domain/usecases/delete_activity_report.dart';
import '../../domain/usecases/generate_activity_report_pdf.dart';
import '../../domain/usecases/get_task_reports.dart';
import '../../domain/usecases/validate_report_draft.dart';
import '../../domain/usecases/verify_report_sha256.dart';

class ActivityReportController extends ChangeNotifier {
  final AssembleReportDraft _assembleReportDraft;
  final ValidateReportDraft _validateReportDraft;
  final GenerateActivityReportPdf _generateActivityReportPdf;
  final GetTaskReports _getTaskReports;
  final DeleteActivityReport _deleteActivityReport;
  final VerifyReportSha256 _verifyReportSha256;

  ActivityReportController({
    required AssembleReportDraft assembleReportDraft,
    required ValidateReportDraft validateReportDraft,
    required GenerateActivityReportPdf generateActivityReportPdf,
    required GetTaskReports getTaskReports,
    required DeleteActivityReport deleteActivityReport,
    required VerifyReportSha256 verifyReportSha256,
  })  : _assembleReportDraft = assembleReportDraft,
        _validateReportDraft = validateReportDraft,
        _generateActivityReportPdf = generateActivityReportPdf,
        _getTaskReports = getTaskReports,
        _deleteActivityReport = deleteActivityReport,
        _verifyReportSha256 = verifyReportSha256;

  ReportDraftData? _draft;
  ReportDraftData? get draft => _draft;

  ReportValidationResult? _validationResult;
  ReportValidationResult? get validationResult => _validationResult;

  List<ActivityReportEntity> _reports = [];
  List<ActivityReportEntity> get reports => _reports;

  ActivityReportEntity? _currentGeneratedReport;
  ActivityReportEntity? get currentGeneratedReport => _currentGeneratedReport;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _generationStage;
  String? get generationStage => _generationStage;

  Future<void> loadDraft(TaskEntity task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _assembleReportDraft(task: task);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (draftData) {
        _draft = draftData;
        _isLoading = false;
        validateDraft();
      },
    );
  }

  Future<void> validateDraft() async {
    if (_draft == null) return;
    final valResult = await _validateReportDraft(draft: _draft!);
    valResult.fold(
      (_) {},
      (res) {
        _validationResult = res;
        notifyListeners();
      },
    );
  }

  void updateNarrative(String narrative) {
    if (_draft == null) return;
    _draft = _draft!.copyWith(narrative: narrative);
    validateDraft();
  }

  void updateTitle(String title) {
    if (_draft == null) return;
    _draft = _draft!.copyWith(title: title);
    validateDraft();
  }

  void updateTemplate(ReportTemplateEntity template) {
    if (_draft == null) return;
    _draft = _draft!.copyWith(template: template);
    notifyListeners();
  }

  void updateSignatures({
    String? supervisorName,
    String? supervisorTitle,
    String? implementerName,
    String? implementerTitle,
  }) {
    if (_draft == null) return;
    _draft = _draft!.copyWith(
      supervisorName: supervisorName,
      supervisorTitle: supervisorTitle,
      implementerName: implementerName,
      implementerTitle: implementerTitle,
    );
    notifyListeners();
  }

  void toggleEvidenceSelection(String evidenceId) {
    if (_draft == null) return;
    final current = List<dynamic>.from(_draft!.selectedEvidence);
    final exists = current.any((e) => e.id == evidenceId);

    // If exists, remove; if not, we would need to find it from all photos
    // Here selectedEvidence holds active items
    if (exists) {
      current.removeWhere((e) => e.id == evidenceId);
    }
    _draft = _draft!.copyWith(selectedEvidence: current.cast());
    validateDraft();
  }

  void reorderEvidence(int oldIndex, int newIndex) {
    if (_draft == null) return;
    final current = List<dynamic>.from(_draft!.selectedEvidence);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    _draft = _draft!.copyWith(selectedEvidence: current.cast());
    notifyListeners();
  }

  void toggleExpenseSelection(String expenseId) {
    if (_draft == null) return;
    final current = List<dynamic>.from(_draft!.selectedExpenses);
    final exists = current.any((e) => e.id == expenseId);
    if (exists) {
      current.removeWhere((e) => e.id == expenseId);
    }
    _draft = _draft!.copyWith(selectedExpenses: current.cast());
    validateDraft();
  }

  Future<ActivityReportEntity?> generatePdfReport() async {
    if (_draft == null) return null;

    _isGenerating = true;
    _errorMessage = null;
    _generationStage = 'Menyiapkan data & tata letak...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _generationStage = 'Mengompilasi foto & lampiran...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _generationStage = 'Menghitung rekonsiliasi pengeluaran...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _generationStage = 'Membuat dokumen PDF A4 & SHA-256...';
    notifyListeners();

    final result = await _generateActivityReportPdf(draft: _draft!);

    _isGenerating = false;
    _generationStage = null;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
      (report) {
        _currentGeneratedReport = report;
        _reports.insert(0, report);
        notifyListeners();
        return report;
      },
    );
  }

  Future<void> loadTaskReports(String taskId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _getTaskReports(taskId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (list) {
        _reports = list;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> verifyReportIntegrity(ActivityReportEntity report) async {
    if (report.pdfLocalPath == null || report.pdfLocalPath!.isEmpty) {
      return false;
    }
    final result = await _verifyReportSha256(
      reportId: report.id,
      localPdfPath: report.pdfLocalPath!,
    );
    return result.fold((_) => false, (isMatch) => isMatch);
  }

  Future<void> deleteReport(String reportId, String taskId) async {
    final result = await _deleteActivityReport(reportId: reportId, taskId: taskId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        _reports.removeWhere((r) => r.id == reportId);
        if (_currentGeneratedReport?.id == reportId) {
          _currentGeneratedReport = null;
        }
        notifyListeners();
      },
    );
  }
}
