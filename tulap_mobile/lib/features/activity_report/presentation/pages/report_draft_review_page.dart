import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/report_template_entity.dart';
import '../controllers/activity_report_controller.dart';
import 'report_preview_page.dart';

class ReportDraftReviewPage extends StatefulWidget {
  final TaskEntity task;

  const ReportDraftReviewPage({super.key, required this.task});

  @override
  State<ReportDraftReviewPage> createState() => _ReportDraftReviewPageState();
}

class _ReportDraftReviewPageState extends State<ReportDraftReviewPage> {
  late ActivityReportController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _narrativeController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

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

    _controller.loadDraft(widget.task).then((_) {
      if (_controller.draft != null) {
        _titleController.text = _controller.draft!.title;
        _narrativeController.text = _controller.draft!.narrative;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _narrativeController.dispose();
    super.dispose();
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
                'Susun Laporan Kegiatan',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Pengaturan Template',
                  onPressed: ctrl.draft == null ? null : () => _showTemplateSheet(context, ctrl),
                ),
              ],
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.draft == null
                    ? Center(
                        child: Text(
                          ctrl.errorMessage ?? 'Gagal memuat draf laporan.',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.base,
                              AppSpacing.base,
                              AppSpacing.base,
                              100,
                            ),
                            children: [
                              // 1. Info Banner
                              _buildInfoBanner(),
                              const SizedBox(height: AppSpacing.base),

                              // 2. Judul Laporan Card
                              _buildCard(
                                title: 'Judul Laporan',
                                icon: Icons.title_rounded,
                                child: TextFormField(
                                  controller: _titleController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.card),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                  onChanged: (val) => ctrl.updateTitle(val),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.base),

                              // 3. Narasi & Ringkasan Pelaksanaan
                              _buildCard(
                                title: 'Ringkasan Pelaksanaan',
                                icon: Icons.subject_rounded,
                                trailing: TextButton.icon(
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Reset Otomatis', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    ctrl.loadDraft(widget.task).then((_) {
                                      if (ctrl.draft != null) {
                                        _narrativeController.text = ctrl.draft!.narrative;
                                      }
                                    });
                                  },
                                ),
                                child: TextFormField(
                                  controller: _narrativeController,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis ringkasan pelaksanaan tugas...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.card),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  onChanged: (val) => ctrl.updateNarrative(val),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.base),

                              // 4. Dokumentasi Foto/Video Terpilih
                              _buildEvidenceSection(ctrl),
                              const SizedBox(height: AppSpacing.base),

                              // 5. Rekapitulasi Pengeluaran Keuangan
                              _buildExpensesSection(ctrl),
                              const SizedBox(height: AppSpacing.base),

                              // 6. Pemeriksaan Validasi Laporan
                              _buildValidationSummaryCard(ctrl),
                            ],
                          ),

                          // Bottom Sticky Button
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.base),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: const Border(top: BorderSide(color: AppColors.border)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: SafeArea(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.button),
                                      ),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_rounded),
                                    label: const Text(
                                      'Buat & Pratinjau PDF',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    onPressed: ctrl.isGenerating
                                        ? null
                                        : () => _handleGenerateAndPreview(context, ctrl),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Loading Overlay saat generate
                          if (ctrl.isGenerating)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        ctrl.generationStage ?? 'Membuat Laporan PDF...',
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tulap.id secara otomatis menyusun draf laporan dari rekaman tugas, foto geotag, dan nota yang telah Anda rekam. Tinjau dan sesuaikan sebelum mengekspor.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: Color(0xFF1E3A8A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(ActivityReportController ctrl) {
    final evidence = ctrl.draft?.selectedEvidence ?? [];

    return _buildCard(
      title: 'Dokumentasi Lapangan (${evidence.length})',
      icon: Icons.photo_library_rounded,
      child: evidence.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada bukti foto yang dipilih.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan atau kecualikan dokumentasi untuk disertakan dalam lampiran laporan resmi:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: evidence.length,
                  onReorder: ctrl.reorderEvidence,
                  itemBuilder: (context, index) {
                    final item = evidence[index];
                    final hasFile = File(item.localFilePath).existsSync();

                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Drag Handle
                          const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 8),

                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: hasFile
                                ? Image.file(
                                    File(item.localFilePath),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      item.isVideo ? Icons.videocam : Icons.photo,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),

                          // Metadata info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item.caption != null && item.caption!.isNotEmpty)
                                      ? item.caption!
                                      : (item.isVideo ? 'Video Bukti' : 'Foto Geotag'),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_dateFormat.format(item.serverTimestamp)} • ±${item.gpsAccuracyMeters.toStringAsFixed(0)}m',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),

                          // Delete / Exclude button
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            tooltip: 'Kecualikan dari Laporan',
                            onPressed: () => ctrl.toggleEvidenceSelection(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildExpensesSection(ActivityReportController ctrl) {
    final expenses = ctrl.draft?.selectedExpenses ?? [];
    final total = ctrl.draft?.totalExpenseSum ?? 0.0;

    return _buildCard(
      title: 'Rekapitulasi Pengeluaran (${expenses.length})',
      icon: Icons.receipt_long_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Realisasi Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Realisasi Terpilih:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ...expenses.map((exp) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    exp.isManualEntry ? Icons.edit_note : Icons.receipt_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.vendorName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          '${exp.category.label} • ${_dateFormat.format(exp.transactionDate)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(exp.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                    onPressed: () => ctrl.toggleExpenseSelection(exp.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValidationSummaryCard(ActivityReportController ctrl) {
    final val = ctrl.validationResult;
    if (val == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: val.isReady ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: val.isReady ? const Color(0xFF10B981) : AppColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                val.isReady ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: val.isReady ? const Color(0xFF059669) : AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                val.isReady ? 'Laporan Siap Dibuat' : 'Pemeriksaan Laporan Diperlukan',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: val.isReady ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (val.warnings.isNotEmpty) ...[
            ...val.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $w', style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F))),
              ),
            ),
          ],
          if (val.blockers.isNotEmpty) ...[
            ...val.blockers.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $b', style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTemplateSheet(BuildContext context, ActivityReportController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final t = ctrl.draft?.template ?? ReportTemplateEntity.defaultActivity;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Tata Letak Laporan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Kop Surat / Header Instansi'),
                    value: t.showHeader,
                    onChanged: (v) {
                      setModalState(() {});
                      ctrl.updateTemplate(t.copyWith(showHeader: v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Kronologi / Linimasa Kegiatan'),
                    value: t.showTimeline,
                    onChanged: (v) {
                      setModalState(() {});
                      ctrl.updateTemplate(t.copyWith(showTimeline: v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Rekapitulasi Pengeluaran Keuangan'),
                    value: t.showExpenses,
                    onChanged: (v) {
                      setModalState(() {});
                      ctrl.updateTemplate(t.copyWith(showExpenses: v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Lampiran Foto Nota / Struk'),
                    value: t.showReceipts,
                    onChanged: (v) {
                      setModalState(() {});
                      ctrl.updateTemplate(t.copyWith(showReceipts: v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Lembar Pengesahan / Tanda Tangan'),
                    value: t.showSignatures,
                    onChanged: (v) {
                      setModalState(() {});
                      ctrl.updateTemplate(t.copyWith(showSignatures: v));
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleGenerateAndPreview(BuildContext context, ActivityReportController ctrl) async {
    final report = await ctrl.generatePdfReport();
    if (!mounted) return;

    if (report != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportPreviewPage(
            report: report,
            task: widget.task,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.errorMessage ?? 'Gagal membuat dokumen PDF.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
