import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/activity_report_entity.dart';
import '../../domain/usecases/verify_report_sha256.dart';

class ReportPreviewPage extends StatefulWidget {
  final ActivityReportEntity report;
  final TaskEntity task;

  const ReportPreviewPage({
    super.key,
    required this.report,
    required this.task,
  });

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  bool _isVerifying = false;
  bool? _isHashValid;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _verifyIntegrity();
  }

  Future<void> _verifyIntegrity() async {
    if (widget.report.pdfLocalPath == null ||
        !File(widget.report.pdfLocalPath!).existsSync()) {
      return;
    }

    setState(() => _isVerifying = true);
    final verifyUsecase = sl<VerifyReportSha256>();
    final result = await verifyUsecase(
      reportId: widget.report.id,
      localPdfPath: widget.report.pdfLocalPath!,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _isHashValid = result.fold((_) => false, (match) => match);
    });
  }

  Future<void> _handleShare() async {
    if (widget.report.pdfLocalPath != null &&
        File(widget.report.pdfLocalPath!).existsSync()) {
      await Share.shareXFiles(
        [XFile(widget.report.pdfLocalPath!)],
        text: 'Laporan Resmi Kegiatan: ${widget.task.taskName} (${widget.report.reportCode})',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File PDF belum tersedia di penyimpanan lokal.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfFile = widget.report.pdfLocalPath != null
        ? File(widget.report.pdfLocalPath!)
        : null;
    final fileExists = pdfFile != null && pdfFile.existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Laporan ${widget.report.formattedVersion}',
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan PDF',
            onPressed: fileExists ? _handleShare : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Provenance & Hash Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
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
                              widget.report.formattedVersion,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.report.reportCode,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Diterbitkan: ${_dateFormat.format(widget.report.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Hash verification badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isHashValid == true
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isHashValid == true
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isHashValid == true ? Icons.verified_rounded : Icons.pending_rounded,
                        size: 14,
                        color: _isHashValid == true ? const Color(0xFF059669) : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isHashValid == true ? 'SHA-256 Valid' : 'Memeriksa',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _isHashValid == true ? const Color(0xFF059669) : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Interactive PDF Viewer
          Expanded(
            child: fileExists
                ? PdfPreview(
                    build: (format) async => pdfFile.readAsBytesSync(),
                    allowPrinting: true,
                    allowSharing: false, // We provide dedicated share button in AppBar
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    maxPageWidth: 700,
                    loadingWidget: const Center(child: CircularProgressIndicator()),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_download_rounded, size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'File PDF ini berada di server cloud dan belum terunduh di perangkat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
