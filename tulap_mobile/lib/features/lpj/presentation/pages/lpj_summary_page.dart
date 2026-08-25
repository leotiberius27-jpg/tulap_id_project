import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/data/datasources/task_local_datasource.dart';
import '../../../task_detail/domain/entities/task_entity.dart';

/// LpjSummaryPage
/// ----------------------------------------------------------------------
/// Layar Ringkasan Laporan Pertanggungjawaban (LPJ) Lapangan otomatis.
/// Menggabungkan realisasi pengeluaran (Nota OCR), bukti visual (Geotag),
/// kepatuhan checklist, dan perbandingan anggaran vs realisasi riil.
/// ----------------------------------------------------------------------
class LpjSummaryPage extends StatefulWidget {
  final String taskId;

  const LpjSummaryPage({super.key, required this.taskId});

  @override
  State<LpjSummaryPage> createState() => _LpjSummaryPageState();
}

class _LpjSummaryPageState extends State<LpjSummaryPage> {
  bool _isLoading = true;
  TaskEntity? _task;
  List<ExpenseNoteEntity> _expenses = [];
  List<GeotagPhotoEntity> _photos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLpjData();
  }

  Future<void> _loadLpjData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = sl<Database>();
      final taskDs = TaskLocalDataSource(db);
      final expenseDs = sl<ExpenseOcrLocalDataSource>();
      final photoDs = sl<GeotagCameraLocalDataSource>();

      final task = await taskDs.getCachedTask(widget.taskId);
      final expenses = await expenseDs.getNotesByTask(widget.taskId);
      final photos = await photoDs.getPhotosByTask(widget.taskId);

      if (!mounted) return;

      if (task == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data kegiatan tidak ditemukan.';
        });
        return;
      }

      setState(() {
        _task = task;
        _expenses = expenses;
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data LPJ: $e';
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  double get _totalRealization =>
      _expenses.fold(0.0, (sum, item) => sum + item.totalAmount);

  double get _budgetRemaining => (_task?.budgetAmount ?? 0) - _totalRealization;

  void _copyLpjSummary() {
    if (_task == null) return;
    final task = _task!;
    HapticFeedback.lightImpact();

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('LAPORAN PERTANGGUNGJAWABAN (LPJ) TULAP.ID');
    buffer.writeln('========================================');
    buffer.writeln('Kode Kegiatan : ${task.taskCode}');
    buffer.writeln('Nama Kegiatan : ${task.taskName}');
    buffer.writeln('Destinasi     : ${task.destination}');
    buffer.writeln('Petugas       : ${task.assigneeName}');
    buffer.writeln(
      'Waktu Pelaks. : ${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
    );
    buffer.writeln('Status        : ${task.status.name.toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('--- RINGKASAN ANGGARAN & BIAYA ---');
    buffer.writeln('Pagu Anggaran : ${_formatCurrency(task.budgetAmount)}');
    buffer.writeln('Total Realisasi : ${_formatCurrency(_totalRealization)}');
    buffer.writeln('Sisa Anggaran : ${_formatCurrency(_budgetRemaining)}');
    buffer.writeln('');
    buffer.writeln(
      '--- RINCIAN NOTA & PENGELUARAN (${_expenses.length} Bukti) ---',
    );
    if (_expenses.isEmpty) {
      buffer.writeln('(Tidak ada catatan pengeluaran)');
    } else {
      for (var i = 0; i < _expenses.length; i++) {
        final exp = _expenses[i];
        buffer.writeln(
          '${i + 1}. [${exp.category.label}] ${exp.vendorName} - ${_formatCurrency(exp.totalAmount)}',
        );
      }
    }
    buffer.writeln('');
    buffer.writeln(
      '--- BUKTI FOTO DOKUMENTASI (${_photos.length} Foto Geotag) ---',
    );
    if (_photos.isEmpty) {
      buffer.writeln('(Tidak ada foto dokumentasi)');
    } else {
      for (var i = 0; i < _photos.length; i++) {
        final p = _photos[i];
        buffer.writeln(
          '${i + 1}. Koordinat: ${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)} (PlusCode: ${p.plusCode ?? "-"})',
        );
        buffer.writeln('   SHA-256: ${p.integrityHash}');
      }
    }
    buffer.writeln('========================================');
    buffer.writeln('Digenerate otomatis oleh Sistem Tulap.id');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan teks LPJ berhasil disalin ke papan klip.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ringkasan LPJ'),
        actions: [
          if (_task != null)
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              tooltip: 'Salin Ringkasan Teks',
              onPressed: _copyLpjSummary,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingView(
        label: 'Menyusun laporan pertanggungjawaban...',
      );
    }

    if (_errorMessage != null || _task == null) {
      return AppErrorState(
        message: _errorMessage ?? 'Data tidak tersedia.',
        onRetry: _loadLpjData,
      );
    }

    final task = _task!;
    final budget = task.budgetAmount;
    final usagePercent = budget > 0
        ? (_totalRealization / budget).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Header Card Identitas LPJ
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iconSoftBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.taskCode,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      task.status.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.taskName,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.destination,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Petugas: ${task.assigneeName}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Bagian Finansial & Anggaran
        Text('RINGKASAN REALISASI ANGGARAN', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pagu Anggaran', style: AppTypography.small),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(budget),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Realisasi', style: AppTypography.small),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(_totalRealization),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: usagePercent,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  color: _totalRealization > budget
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Penggunaan: ${(usagePercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Sisa: ${_formatCurrency(_budgetRemaining)}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _budgetRemaining < 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Rincian Pengeluaran (Nota)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RINCIAN PENGELUARAN NOTA', style: AppTypography.sectionLabel),
            Text('${_expenses.length} nota', style: AppTypography.small),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_expenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Belum ada nota yang tercatat untuk kegiatan ini.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _expenses[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.iconSoftCyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.vendorName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${item.category.label} • ${_formatDate(item.transactionDate)}',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(item.totalAmount),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.lg),

        // Bukti Foto Lapangan (Geotag)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DOKUMENTASI FOTO BUKTI', style: AppTypography.sectionLabel),
            Text('${_photos.length} foto', style: AppTypography.small),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Belum ada foto geotag yang diambil.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 110,
                    height: 110,
                    color: AppColors.border,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(photo.localFilePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.iconSoftBlue,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '±${photo.gpsAccuracyMeters.round()}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }
}
