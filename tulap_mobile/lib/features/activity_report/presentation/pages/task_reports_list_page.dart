import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../controllers/activity_report_controller.dart';
import 'report_draft_review_page.dart';
import 'report_preview_page.dart';

class TaskReportsListPage extends StatefulWidget {
  final TaskEntity task;

  const TaskReportsListPage({super.key, required this.task});

  @override
  State<TaskReportsListPage> createState() => _TaskReportsListPageState();
}

class _TaskReportsListPageState extends State<TaskReportsListPage> {
  late ActivityReportController _controller;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _controller = ActivityReportController(
      assembleReportDraft: sl(),
      validateReportDraft: sl(),
      generateActivityReportPdf: sl(),
      getTaskReports: sl(),
      deleteActivityReport: sl(),
      verifyReportSha256: sl(),
    );
    _controller.loadTaskReports(widget.task.id);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityReportController>.value(
      value: _controller,
      child: Consumer<ActivityReportController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Arsip Laporan Kegiatan',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Buat Laporan Baru',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportDraftReviewPage(task: widget.task),
                      ),
                    );
                    _controller.loadTaskReports(widget.task.id);
                  },
                ),
              ],
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.reports.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                size: 56,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Laporan Dibuat',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Kompilasi dokumentasi foto, linimasa, dan rekapitulasi nota tugas ini menjadi laporan resmi format PDF.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.button),
                                  ),
                                ),
                                icon: const Icon(Icons.post_add_rounded),
                                label: const Text('Buat Laporan Sekarang'),
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportDraftReviewPage(task: widget.task),
                                    ),
                                  );
                                  _controller.loadTaskReports(widget.task.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount: ctrl.reports.length,
                        itemBuilder: (context, index) {
                          final report = ctrl.reports[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportPreviewPage(
                                        report: report,
                                        task: widget.task,
                                      ),
                                    ),
                                  );
                                  _controller.loadTaskReports(widget.task.id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // PDF Document Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Main info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    report.formattedVersion,
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 11,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    report.reportCode,
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 13.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _dateFormat.format(report.createdAt),
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  '${report.evidenceCount} Foto • ${report.receiptCount} Nota',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: report.isSynced
                                                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                        : Colors.orange.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    report.isSynced ? 'Tersinkron' : 'Lokal',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: report.isSynced
                                                          ? const Color(0xFF059669)
                                                          : Colors.orange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
