import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/presentation/pages/geotag_camera_entry_page.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_detail_controller.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/task_status_banner.dart';

/// TaskDetailPage
/// ----------------------------------------------------------------------
/// Layar Detail Tugas sesuai Bagian 11.2 spesifikasi - pusat kendali
/// satu tugas: instruksi, checklist, bukti, status. Halaman inilah
/// yang menyatukan seluruh fitur yang sudah dibangun sebelumnya:
/// GeotagCameraEntryPage, ReceiptScannerEntryPage, dan checklist lokal.
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<TaskDetailController>(
        builder: (context, controller, _) {
          final state = controller.state;

          if (state.status == TaskDetailStatus.loading && state.task == null) {
            return const AppLoadingView(label: 'Memuat detail tugas...');
          }

          if (state.status == TaskDetailStatus.error && state.task == null) {
            return _buildErrorState(context, controller, state.errorMessage);
          }

          final task = state.task!;

          return RefreshIndicator(
            onRefresh: controller.loadTask,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _buildHeader(task),
                const SizedBox(height: AppSpacing.lg),
                _buildChecklistSection(context, controller, task),
                const SizedBox(height: AppSpacing.lg),
                _buildEvidenceSection(context, controller, task),
                const SizedBox(height: AppSpacing.xl),
                _buildPrimaryCta(context, controller, state, task),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TaskEntity task) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(task.taskName, style: AppTypography.pageTitle),
              ),
              TaskStatusBanner(status: task.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('#${task.taskCode}', style: AppTypography.small),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(icon: Icons.location_on_outlined, text: task.destination),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                '${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(task.description!, style: AppTypography.bodySecondary),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistSection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CHECKLIST', style: AppTypography.sectionLabel),
              Text(
                '${task.completedChecklistCount} dari ${task.checklistItems.length} selesai',
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: task.checklistProgress,
              backgroundColor: AppColors.background,
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < task.checklistItems.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            ChecklistItemTile(
              item: task.checklistItems[i],
              onToggle: (value) =>
                  controller.toggleItem(task.checklistItems[i].id, value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(
    BuildContext context,
    TaskDetailController controller,
    TaskEntity task,
  ) {
    return Row(
      children: [
        Expanded(
          child: _EvidenceActionCard(
            icon: Icons.camera_alt_outlined,
            iconBackground: AppColors.iconSoftBlue,
            label: 'Foto Kegiatan',
            count: task.geotagPhotoCount,
            onTap: () async {
              final photo = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GeotagCameraEntryPage(
                    officerName: officerName,
                    agencyName: agencyName,
                    taskId: task.id,
                  ),
                ),
              );
              if (photo == null || !context.mounted) return;
              await controller.loadTask();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto berhasil disimpan.')),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _EvidenceActionCard(
            icon: Icons.receipt_long_outlined,
            iconBackground: AppColors.iconSoftCyan,
            label: 'Scan Nota',
            count: task.expenseNoteCount,
            onTap: () async {
              final note = await Navigator.of(context).push<ExpenseNoteEntity>(
                MaterialPageRoute(
                  builder: (_) => ReceiptScannerEntryPage(taskId: task.id),
                ),
              );
              if (note == null || !context.mounted) return;
              await controller.loadTask();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    note.isPossibleDuplicate
                        ? 'Nota tersimpan - nota ini tampaknya sudah pernah digunakan sebelumnya.'
                        : 'Nota berhasil disimpan.',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCta(
    BuildContext context,
    TaskDetailController controller,
    TaskDetailState state,
    TaskEntity task,
  ) {
    if (task.status == TaskStatusEntity.draft) {
      return ElevatedButton(
        onPressed: state.status == TaskDetailStatus.submitting
            ? null
            : () async {
                final success = await controller.startTask();
                if (context.mounted && !success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.state.errorMessage ??
                            'Gagal memulai tugas.',
                      ),
                    ),
                  );
                }
              },
        child: state.status == TaskDetailStatus.submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Mulai Tugas'),
      );
    }

    if (task.status == TaskStatusEntity.ongoing ||
        task.status == TaskStatusEntity.revisionNeeded) {
      final revisionBanner = task.status == TaskStatusEntity.revisionNeeded
          ? _StatusInfoBanner(
              icon: Icons.edit_note,
              color: AppColors.warning,
              background: AppColors.warningSoft,
              message: task.latestRevisionNote ??
                  'Perlu diperbaiki. Hubungi atasan untuk rincian.',
            )
          : null;

      if (!task.isReadyToSubmit) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (revisionBanner != null) ...[
              revisionBanner,
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              '${task.incompleteMandatoryItems.length} bukti wajib belum lengkap.',
              style: AppTypography.small.copyWith(color: AppColors.warning),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const OutlinedButton(
              onPressed: null, // Item wajib sudah terlihat di checklist di atas
              child: Text('Lengkapi Bukti'),
            ),
          ],
        );
      }

      final submitButton = ElevatedButton(
        onPressed: state.status == TaskDetailStatus.submitting
            ? null
            : () async {
                final success = await controller.submitForVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Tugas berhasil dikirim untuk verifikasi.'
                            : controller.state.errorMessage ??
                                  'Gagal mengirim tugas.',
                      ),
                    ),
                  );
                }
              },
        child: state.status == TaskDetailStatus.submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Kirim Tugas'),
      );

      if (revisionBanner == null) return submitButton;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          revisionBanner,
          const SizedBox(height: AppSpacing.sm),
          submitButton,
        ],
      );
    }

    if (task.status == TaskStatusEntity.pendingVerification) {
      return const _StatusInfoBanner(
        icon: Icons.hourglass_top,
        color: AppColors.warning,
        background: AppColors.warningSoft,
        message: 'Tugas sedang menunggu verifikasi atasan.',
      );
    }

    if (task.status == TaskStatusEntity.verified ||
        task.status == TaskStatusEntity.completed) {
      return const _StatusInfoBanner(
        icon: Icons.check_circle,
        color: AppColors.success,
        background: AppColors.successSoft,
        message: 'Tugas ini sudah selesai dan terverifikasi.',
      );
    }

    if (task.status == TaskStatusEntity.rejected) {
      return _StatusInfoBanner(
        icon: Icons.cancel,
        color: AppColors.danger,
        background: AppColors.dangerSoft,
        message: task.latestRevisionNote ??
            'Tugas ini ditolak. Hubungi atasan untuk informasi lebih lanjut.',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(
    BuildContext context,
    TaskDetailController controller,
    String? message,
  ) {
    return AppErrorState(
      message: message ?? 'Tugas belum bisa dimuat.',
      onRetry: controller.loadTask,
      icon: Icons.error_outline,
      iconColor: AppColors.danger,
      retryLabel: 'Muat Ulang',
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _StatusInfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String message;

  const _StatusInfoBanner({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTypography.bodySecondary)),
      ],
    );
  }
}

class _EvidenceActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _EvidenceActionCard({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
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
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.action, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text('$count item', style: AppTypography.small),
          ],
        ),
      ),
    );
  }
}
