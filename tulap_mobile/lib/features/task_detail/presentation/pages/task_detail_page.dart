import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Detail Tugas')),
      body: Consumer<TaskDetailController>(
        builder: (context, controller, _) {
          final state = controller.state;

          if (state.status == TaskDetailStatus.loading && state.task == null) {
            return const Center(child: CircularProgressIndicator());
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
                _buildEvidenceSection(context, task),
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(task.taskName, style: AppTypography.pageTitle)),
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
            text: '${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Checklist', style: AppTypography.sectionTitle),
              Text(
                '${task.completedChecklistCount}/${task.checklistItems.length} selesai',
                style: AppTypography.small,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.checklistProgress,
              backgroundColor: AppColors.background,
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...task.checklistItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ChecklistItemTile(
                item: item,
                onToggle: (value) => controller.toggleItem(item.id, value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(BuildContext context, TaskEntity task) {
    return Row(
      children: [
        Expanded(
          child: _EvidenceActionCard(
            icon: Icons.camera_alt_outlined,
            label: 'Foto Kegiatan',
            count: task.geotagPhotoCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GeotagCameraEntryPage(
                  officerName: officerName,
                  agencyName: agencyName,
                  taskId: task.id,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _EvidenceActionCard(
            icon: Icons.receipt_long_outlined,
            label: 'Scan Nota',
            count: task.expenseNoteCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiptScannerEntryPage(taskId: task.id),
              ),
            ),
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
        onPressed: () async => controller.startTask(),
        child: const Text('Lanjutkan Tugas'),
      );
    }

    if (task.status == TaskStatusEntity.ongoing ||
        task.status == TaskStatusEntity.revisionNeeded) {
      if (!task.isReadyToSubmit) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

      return ElevatedButton(
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
                            : controller.state.errorMessage ?? 'Gagal mengirim tugas.',
                      ),
                    ),
                  );
                }
              },
        child: state.status == TaskDetailStatus.submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Kirim Tugas'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(
    BuildContext context,
    TaskDetailController controller,
    String? message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'Tugas belum bisa dimuat.',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: controller.loadTask, child: const Text('Muat Ulang')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
  final String label;
  final int count;
  final VoidCallback onTap;

  const _EvidenceActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.action, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('$count item', style: AppTypography.small),
          ],
        ),
      ),
    );
  }
}
