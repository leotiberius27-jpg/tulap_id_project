import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
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
///
/// Tidak lagi membuat `TaskListController` sendiri - controller-nya
/// dibuat & dipegang oleh `MainShell` (di luar `IndexedStack`) supaya
/// bisa dipanggil `.load()` ulang saat tab ini dipilih, lihat catatan
/// di MainShell soal kenapa itu perlu.
/// ----------------------------------------------------------------------
class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) => const _TaskListView();
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
              return const AppLoadingView(label: 'Memuat tugas...');
            }

            if (state.status == TaskListStatus.error) {
              return AppErrorState(
                message: state.errorMessage ?? 'Data belum berhasil dimuat.',
                onRetry: controller.load,
              );
            }

            if (state.tasks.isEmpty) {
              // Dibungkus RefreshIndicator + ListView (bukan langsung
              // AppEmptyState) supaya tetap bisa ditarik-refresh saat
              // kosong - status tugas bisa berubah dari perangkat lain
              // (verifikasi lewat web dashboard) tanpa ada notifikasi
              // apa pun ke tab ini, lihat catatan refresh di MainShell.
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    AppEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'Belum ada tugas aktif',
                      message: 'Tugas baru dari instansi akan muncul di sini.',
                    ),
                  ],
                ),
              );
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
            getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
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

