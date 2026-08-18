import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';
import '../controllers/task_list_controller.dart';

/// TaskListPage (Tugas)
/// ----------------------------------------------------------------------
/// Tab "Tugas" di bottom navigation - menampilkan SEMUA tugas aktif
/// pegawai (Bagian 21/23 master prompt), bukan hanya satu yang disorot
/// di Beranda. Setiap kartu membuka Detail Tugas yang sama persis
/// dengan yang dipakai dari Beranda.
/// ----------------------------------------------------------------------
class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskListController>(
      create: (_) => TaskListController(
        getActiveTasks: sl<GetActiveTasks>(),
        getCurrentSession: sl<GetCurrentSession>(),
      ),
      child: const _TaskListView(),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tugas')),
      body: SafeArea(
        top: false,
        // Padding bawah tetap agar tombol kamera tengah (FAB centerDocked
        // di MainShell) tidak menutupi konten terakhir - lihat catatan
        // yang sama di HomePage.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Consumer<TaskListController>(
          builder: (context, controller, _) {
            final state = controller.state;

            if (state.status == TaskListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == TaskListStatus.error) {
              return _ErrorState(
                message: state.errorMessage ?? 'Data belum berhasil dimuat.',
                onRetry: controller.load,
              );
            }

            if (state.tasks.isEmpty) {
              return const _EmptyState();
            }

            final officerName = state.user?.fullName ?? 'Pengguna';
            final agencyName =
                state.user?.instansiName ?? 'Instansi tidak diketahui';

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.base),
                itemCount: state.tasks.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  return _TaskListCard(
                    task: task,
                    onTap: () => _openTaskDetail(
                      context,
                      taskId: task.id,
                      officerName: officerName,
                      agencyName: agencyName,
                    ),
                  );
                },
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  void _openTaskDetail(
    BuildContext context, {
    required String taskId,
    required String officerName,
    required String agencyName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskDetailController>(
          create: (_) => TaskDetailController(
            getTaskDetail: sl<GetTaskDetail>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            startTask: sl<StartTask>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            taskId: taskId,
          ),
          child: TaskDetailPage(
            officerName: officerName,
            agencyName: agencyName,
          ),
        ),
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const _TaskListCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
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
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TaskStatusBanner(status: task.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.destination,
                      style: AppTypography.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task.checklistItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: task.checklistProgress,
                          backgroundColor: AppColors.background,
                          color: AppColors.success,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${task.completedChecklistCount}/${task.checklistItems.length}',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Belum ada tugas aktif', style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            const Text(
              'Tugas baru dari instansi akan muncul di sini.',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTypography.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
