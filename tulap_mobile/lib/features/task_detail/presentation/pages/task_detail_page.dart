import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../evidence_gallery/presentation/pages/activity_gallery_page.dart';
import '../../../evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../expense_ocr/presentation/pages/activity_expenses_page.dart';
import '../../../expense_ocr/presentation/pages/manual_expense_page.dart';
import '../../../expense_ocr/presentation/pages/receipt_detail_page.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../../location/presentation/pages/location_page.dart';
import '../../domain/entities/activity_note_entity.dart';
import '../../../activity_report/presentation/pages/report_draft_review_page.dart';
import '../../../activity_report/presentation/pages/task_reports_list_page.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_detail_controller.dart';
import '../widgets/activity_timeline_card.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/task_gallery_hero.dart';
import '../widgets/task_status_banner.dart';

/// TaskDetailPage (Activity Workspace / Workspace Kegiatan Aktif)
/// ----------------------------------------------------------------------
/// Pusat Operasional Kegiatan Lapangan Tulap.id:
/// 1. Header & Galeri Hero Bukti (Paging horizontal, preload, status banner)
/// 2. Identitas Kegiatan (Judul, Status, Lokasi, Rentang Waktu, Deskripsi)
/// 3. Progres Kegiatan (Persentase + 4 Counter: Checklist, Dokumentasi, Nota, Catatan)
/// 4. Aksi Lapangan (2x2 Grid: 📷 Foto, 🧾 Scan Nota, 📝 Catatan, 📍 Lokasi)
/// 5. Checklist Kegiatan (Interaktif, Simpan SQLite Lokal, Event Linimasa)
/// 6. Galeri Dokumentasi Horizontal ([Foto 1] [Foto 2] ... [+])
/// 7. Nota & Pengeluaran (Daftar Nota, Kategori, Nominal IDR, Total Pengeluaran)
/// 8. Catatan Lapangan (+ Tambah Catatan, Waktu, Riwayat Catatan)
/// 9. Linimasa Kejadian Otomatis (Event Feed: Dimulai, Foto, Nota, Checklist, dll)
/// 10. Status Penyimpanan Lokal & Sinkronisasi Cloud
/// 11. Sticky Footer CTA: [Simpan & Lanjutkan Nanti] dan [Selesaikan Kegiatan]
/// ----------------------------------------------------------------------
class TaskDetailPage extends StatelessWidget {
  final String officerName;
  final String agencyName;

  const TaskDetailPage({
    super.key,
    required this.officerName,
    required this.agencyName,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Consumer<TaskDetailController>(
        builder: (context, controller, _) {
          final state = controller.state;

          if (state.status == TaskDetailStatus.loading && state.task == null) {
            return const AppLoadingView(label: 'Memuat workspace kegiatan...');
          }

          if (state.status == TaskDetailStatus.error && state.task == null) {
            return _buildErrorState(context, controller, state.errorMessage);
          }

          final task = state.task!;

          return RefreshIndicator(
            onRefresh: controller.loadTask,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // 1. Galeri Hero Carousel di Bagian Atas
                TaskGalleryHero(
                  photos: state.photos,
                  task: task,
                  onBack: () => Navigator.of(context).pop(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Kartu Identitas Kegiatan
                      _buildIdentityCard(task),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Progres & Ringkasan Kegiatan (Checklist, Dokumentasi, Nota, Catatan)
                      _buildProgressSection(task, state),
                      const SizedBox(height: AppSpacing.xl),

                      // 4. Aksi Lapangan Utama (2x2 Grid: Foto, Nota, Catatan, Lokasi)
                      _buildFieldActionsGrid(context, controller, task),
                      const SizedBox(height: AppSpacing.xl),

                      // 5. Checklist Kegiatan
                      _buildChecklistSection(context, controller, task),
                      const SizedBox(height: AppSpacing.xl),

                      // 6. Dokumentasi Foto Lapangan
                      _buildEvidenceGallerySection(
                        context,
                        controller,
                        task,
                        state.photos,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 7. Nota & Pengeluaran
                      _buildExpensesSection(
                        context,
                        controller,
                        task,
                        state.expenses,
                        currencyFormatter,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 8. Catatan Lapangan
                      _buildNotesSection(
                        context,
                        controller,
                        task,
                        state.notes,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 9. Laporan Kegiatan & LPJ Foundation
                      _buildReportsSection(
                        context,
                        task,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 10. Linimasa Kejadian Kegiatan
                      Text(
                        'LINIMASA KEGIATAN',
                        style: AppTypography.sectionLabel,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ActivityTimelineCard(events: state.timelineEvents),
                      const SizedBox(height: AppSpacing.lg),

                      // 10. Status Penyimpanan & Sinkronisasi
                      _buildStorageSyncBar(state),

                      // Ruang ekstra di bawah untuk mencegah terpotong oleh sticky bottom CTA
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<TaskDetailController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final task = state.task;
          if (task == null) return const SizedBox.shrink();

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: _buildFooterCta(context, controller, state, task),
            ),
          );
        },
      ),
    );
  }

  // ====================================================================
  // 1. KARTU IDENTITAS KEGIATAN
  // ====================================================================
  Widget _buildIdentityCard(TaskEntity task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Kegiatan + Status Chip (Responsive LayoutBuilder)
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;
              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    TaskStatusBanner(status: task.status),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusBanner(status: task.status),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Lokasi Kegiatan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatLocation(task.destination),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tanggal Kegiatan (Human-readable Indonesian format, fully responsive)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatActivityDateRange(task.startDate, task.endDate),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (task.description != null &&
              task.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              task.description!.trim(),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ====================================================================
  // 2. PROGRES KEGIATAN & RINGKASAN DATA
  // ====================================================================
  Widget _buildProgressSection(TaskEntity task, TaskDetailState state) {
    final progress = task.checklistProgress;
    final progressPercent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progres Kegiatan',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              color: progress >= 1.0 ? AppColors.success : AppColors.action,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4 Counter Pill Row
          Row(
            children: [
              _buildProgressPill(
                icon: Icons.checklist_rounded,
                count:
                    '${task.completedChecklistCount}/${task.checklistItems.length}',
                label: 'Checklist',
              ),
              const SizedBox(width: 6),
              _buildProgressPill(
                icon: Icons.camera_alt_outlined,
                count: '${state.photos.length}',
                label: 'Foto',
              ),
              const SizedBox(width: 6),
              _buildProgressPill(
                icon: Icons.receipt_long_outlined,
                count: '${state.expenses.length}',
                label: 'Nota',
              ),
              const SizedBox(width: 6),
              _buildProgressPill(
                icon: Icons.note_alt_outlined,
                count: '${state.notes.length}',
                label: 'Catatan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count $label',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 3. AKSI LAPANGAN UTAMA (2x2 GRID)
  // ====================================================================
  Widget _buildFieldActionsGrid(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AKSI LAPANGAN', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Foto',
                subtitle: 'Dokumentasi',
                color: const Color(0xFF0D6EFD),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GeotagCameraEntryPage(
                        officerName: officerName,
                        agencyName: agencyName,
                        taskId: task.id,
                        taskName: task.taskName,
                      ),
                    ),
                  );
                  if (context.mounted) {
                    controller.loadTask();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionTile(
                icon: Icons.document_scanner_rounded,
                title: 'Scan Nota',
                subtitle: 'Pengeluaran',
                color: const Color(0xFF10B981),
                onTap: () async {
                  final note = await Navigator.of(context)
                      .push<ExpenseNoteEntity>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReceiptScannerEntryPage(taskId: task.id),
                        ),
                      );
                  if (context.mounted && note != null) {
                    controller.loadTask();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.edit_note_rounded,
                title: 'Catatan',
                subtitle: 'Lapangan',
                color: const Color(0xFFF59E0B),
                onTap: () => _openAddNoteDialog(context, controller),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionTile(
                icon: Icons.my_location_rounded,
                title: 'Lokasi',
                subtitle: 'Detail GPS',
                color: const Color(0xFF6366F1),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LocationPage(taskDestination: task.destination),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 4. CHECKLIST KEGIATAN
  // ====================================================================
  Widget _buildChecklistSection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
  ) {
    final items = task.checklistItems;
    final completedCount = task.completedChecklistCount;
    final totalCount = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CHECKLIST KEGIATAN',
                style: AppTypography.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$completedCount dari $totalCount selesai',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Tidak ada item checklist pada tugas ini.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.border,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return ChecklistItemTile(
                  item: item,
                  onToggle: (val) {
                    if (!task.status.isFinal) {
                      controller.toggleItem(item.id, val);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // ====================================================================
  // 5. DOKUMENTASI FOTO LAPANGAN (HORIZONTAL PREVIEW)
  // ====================================================================
  Widget _buildEvidenceGallerySection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
    List<GeotagPhotoEntity> photos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'DOKUMENTASI FOTO',
                style: AppTypography.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (photos.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivityGalleryPage(
                        taskId: task.id,
                        taskName: task.taskName,
                        task: task,
                      ),
                    ),
                  ).then((_) => controller.loadTask());
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Text(
                '${photos.length} bukti tersimpan',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length + 1,
            itemBuilder: (context, index) {
              if (index == photos.length) {
                // Tombol Tambah Foto (+)
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GeotagCameraEntryPage(
                            officerName: officerName,
                            agencyName: agencyName,
                            taskId: task.id,
                            taskName: task.taskName,
                          ),
                        ),
                      );
                      if (context.mounted) {
                        controller.loadTask();
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final photo = photos[index];
              final path = photo.localFilePath;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => _openFullscreenPhotoDetail(
                    context,
                    photo,
                    index,
                    photos.length,
                    photos,
                    task,
                    controller,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPhotoThumbnail(path),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 6. NOTA & PENGELUARAN
  // ====================================================================
  Widget _buildExpensesSection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
    List<ExpenseNoteEntity> expenses,
    NumberFormat formatter,
  ) {
    final totalAmount = expenses.fold(0.0, (s, e) => s + e.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NOTA & PENGELUARAN',
                style: AppTypography.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (expenses.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivityExpensesPage(task: task),
                    ),
                  );
                  if (context.mounted) {
                    controller.loadTask();
                  }
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              formatter.format(totalAmount),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Belum ada nota pengeluaran tercatat.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Scan'),
                        onPressed: () async {
                          final note = await Navigator.of(context)
                              .push<ExpenseNoteEntity>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReceiptScannerEntryPage(taskId: task.id),
                                ),
                              );
                          if (context.mounted && note != null) {
                            controller.loadTask();
                          }
                        },
                      ),
                    ],
                  ),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: expenses.length > 3 ? 3 : expenses.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.border,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        onTap: () async {
                          final changed = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReceiptDetailPage(
                                expense: exp,
                                task: task,
                              ),
                            ),
                          );
                          if (context.mounted && changed == true) {
                            controller.loadTask();
                          }
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          exp.vendorName,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          '${exp.category.label} • ${DateFormat('dd MMM yyyy').format(exp.transactionDate)}',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          formatter.format(exp.totalAmount),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total ${expenses.length} Transaksi',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Manual'),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManualExpensePage(taskId: task.id),
                            ),
                          );
                          if (context.mounted && result != null) {
                            controller.loadTask();
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.document_scanner_rounded,
                          size: 16,
                        ),
                        label: const Text('+ Scan Nota'),
                        onPressed: () async {
                          final note = await Navigator.of(context)
                              .push<ExpenseNoteEntity>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReceiptScannerEntryPage(taskId: task.id),
                                ),
                              );
                          if (context.mounted && note != null) {
                            controller.loadTask();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 7. CATATAN LAPANGAN
  // ====================================================================
  Widget _buildNotesSection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
    List<ActivityNoteEntity> notes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CATATAN LAPANGAN',
                style: AppTypography.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Tambah'),
              onPressed: () => _openAddNoteDialog(context, controller),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (notes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Belum ada catatan lapangan. Tekan + Tambah untuk mencatat temuan atau instruksi tambahan.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Catatan #${notes.length - index}',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM HH:mm').format(note.createdAt),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.content,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ====================================================================
  // 8. LAPORAN KEGIATAN (SMART ACTIVITY REPORT & LPJ)
  // ====================================================================
  Widget _buildReportsSection(
    BuildContext context,
    TaskEntity task,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'LAPORAN KEGIATAN & LPJ',
                style: AppTypography.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.history_rounded, size: 16),
              label: const Text('Riwayat Arsip'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskReportsListPage(task: task),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kompilasi Laporan Cerdas',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ekspor bukti foto geotag, linimasa, & rekap nota ke PDF resmi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 280;
                  if (isCompact) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text(
                              'Buat Laporan',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportDraftReviewPage(task: task),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.folder_open_rounded, size: 16),
                            label: const Text(
                              'Arsip Laporan',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TaskReportsListPage(task: task),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text(
                            'Buat Laporan',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportDraftReviewPage(task: task),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: const Text(
                            'Arsip Laporan',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaskReportsListPage(task: task),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 9. STATUS PENYIMPANAN & SINKRONISASI
  // ====================================================================
  Widget _buildStorageSyncBar(TaskDetailState state) {
    final storedCount = state.totalLocalStoredItems;
    final pendingCount = state.pendingSyncCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            size: 18,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? '$storedCount data lokal tersimpan  •  $pendingCount menunggu sinkronisasi'
                  : '$storedCount data lokal tersimpan  •  Semua sinkron',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 9. FOOTER STICKY CTA (Simpan & Lanjutkan Nanti + Selesaikan Kegiatan)
  // ====================================================================
  Widget _buildFooterCta(
    BuildContext context,
    TaskDetailController controller,
    TaskDetailState state,
    TaskEntity task,
  ) {
    final isSubmitting = state.status == TaskDetailStatus.submitting;

    if (task.status.isFinal) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: const Text('Kembali ke Beranda'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        final saveButton = SizedBox(
          height: 48,
          width: isNarrow ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Simpan & Lanjutkan Nanti',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );

        final completeButton = SizedBox(
          height: 48,
          width: isNarrow ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () => _handleCompleteActivity(context, controller, task),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.action,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Selesaikan Kegiatan',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [completeButton, const SizedBox(height: 8), saveButton],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: saveButton),
            const SizedBox(width: 10),
            Expanded(flex: 6, child: completeButton),
          ],
        );
      },
    );
  }

  // ====================================================================
  // 10. DIALOGS & ACTION HANDLERS
  // ====================================================================
  void _openAddNoteDialog(
    BuildContext context,
    TaskDetailController controller,
  ) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Catatan Lapangan Baru',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Tuliskan catatan, kondisi aset, atau temuan lapangan...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.of(ctx).pop();
                    final success = await controller.addNote(text);
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catatan lapangan berhasil disimpan.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Simpan Catatan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteActivity(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
  ) async {
    final incomplete = task.incompleteMandatoryItems;

    if (incomplete.isNotEmpty) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          ),
          title: const Text('Checklist Belum Lengkap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ada ${incomplete.length} butir checklist wajib yang belum dicentang:',
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              ...incomplete.map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          i.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda tetap ingin menyelesaikan kegiatan ini sekarang?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Lengkapi Dulu'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Tetap Selesaikan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    final success = await controller.submitForVerification();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kegiatan berhasil diselesaikan dan masuk ke Riwayat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final err =
          controller.state.errorMessage ?? 'Gagal menyelesaikan kegiatan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildErrorState(
    BuildContext context,
    TaskDetailController controller,
    String? message,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Kegiatan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message ?? 'Kegiatan tidak ditemukan.',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: controller.loadTask,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    } else if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }

  void _openFullscreenPhotoDetail(
    BuildContext context,
    GeotagPhotoEntity photo,
    int index,
    int total,
    List<GeotagPhotoEntity> photos,
    TaskEntity task,
    TaskDetailController controller,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvidenceViewerPage(
          initialEvidenceList: photos,
          initialIndex: index,
          taskId: task.id,
          taskName: task.taskName,
          task: task,
        ),
      ),
    ).then((_) => controller.loadTask());
  }

  void _showExpenseDetailDialog(
    BuildContext context,
    ExpenseNoteEntity expense,
    NumberFormat formatter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rincian Nota Pengeluaran',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Vendor / Toko', expense.vendorName),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDetailRow(
                    'Kategori',
                    expense.category.name.toUpperCase(),
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDetailRow(
                    'Tanggal Transaksi',
                    DateFormat('dd MMMM yyyy').format(expense.transactionDate),
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDetailRow(
                    'Total Pembayaran',
                    formatter.format(expense.totalAmount),
                    isBold: true,
                  ),
                  if (expense.receiptNumber != null &&
                      expense.receiptNumber!.isNotEmpty) ...[
                    const Divider(color: AppColors.border, height: 16),
                    _buildDetailRow('No. Struk', expense.receiptNumber!),
                  ],
                  if (expense.isPossibleDuplicate) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Peringatan: Terdeteksi kesamaan dengan nota lain.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatLocation(String rawLocation) {
    var loc = rawLocation.trim();
    if (loc.isEmpty) return 'Lokasi belum ditentukan';
    if (loc == 'Timika Papua') return 'Timika, Papua';
    return loc;
  }

  String _formatActivityDateRange(DateTime start, DateTime end) {
    return AppDateFormatter.formatDateRange(start, end);
  }
}
