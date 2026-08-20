import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';
import '../controllers/history_controller.dart';

/// HistoryPage (Riwayat)
/// ----------------------------------------------------------------------
/// Tab "Riwayat" - tugas yang sudah tuntas (verified/rejected/completed),
/// lihat HistoryController. Ini riwayat TUGAS, bukan riwayat aktivitas
/// granular (per-foto/per-nota/per-sync) - audit trail sedetail itu
/// butuh infrastruktur backend yang belum ada. Menampilkan data asli
/// tugas yang sudah dipilah lewat status, bukan data rekayasa.
///
/// Tidak lagi membuat `HistoryController` sendiri - controller-nya
/// dibuat & dipegang oleh `MainShell` (di luar `IndexedStack`) supaya
/// bisa dipanggil `.load()` ulang saat tab ini dipilih, lihat catatan
/// di MainShell soal kenapa itu perlu.
/// ----------------------------------------------------------------------
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => const _HistoryView();
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Consumer<HistoryController>(
            builder: (context, controller, _) {
              final state = controller.state;

              if (state.status == HistoryStatus.loading) {
                return const AppLoadingView(label: 'Memuat riwayat...');
              }

              if (state.status == HistoryStatus.error) {
                return AppErrorState(
                  message: state.errorMessage ?? 'Riwayat belum berhasil dimuat.',
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
                        icon: Icons.history,
                        title: 'Belum ada riwayat',
                        message:
                            'Tugas yang sudah selesai diverifikasi, ditolak, '
                            'atau tuntas akan muncul di sini.',
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
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    return _HistoryCard(
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

class _HistoryCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const _HistoryCard({required this.task, required this.onTap});

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
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
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
            ],
          ),
        ),
      ),
    );
  }
}
