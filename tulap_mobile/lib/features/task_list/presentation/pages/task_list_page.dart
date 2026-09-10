import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../subscription/presentation/utils/activity_quota_guard.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/create_activity_page.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../task_detail/presentation/widgets/task_status_banner.dart';
import '../../../travel_mission/presentation/pages/travel_mission_list_page.dart';
import '../controllers/task_list_controller.dart';

/// TaskListPage (Tugas & Kegiatan)
/// ----------------------------------------------------------------------
/// Tab "Tugas" di bottom navigation - menampilkan SEMUA tugas & kegiatan aktif
/// pegawai, dilengkapi filter status (Semua, Sedang Berjalan, Belum Dimulai, Belum Lengkap).
/// Setiap kartu membuka Activity Workspace (TaskDetailPage).
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tugas & Kegiatan',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flight_takeoff_rounded),
            tooltip: 'Perjalanan Dinas (SPPD)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TravelMissionListPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Buat Kegiatan Lapangan',
            onPressed: () async {
              final canCreate = await ensureActivityQuotaAvailable(context);
              if (!canCreate || !context.mounted) return;
              final created = await Navigator.of(context).push<TaskEntity>(
                MaterialPageRoute(builder: (_) => const CreateActivityPage()),
              );
              if (created != null && context.mounted) {
                context.read<TaskListController>().load();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Consumer<TaskListController>(
            builder: (context, controller, _) {
              final state = controller.state;

              if (state.status == TaskListStatus.loading) {
                return const AppLoadingView(
                  label: 'Memuat tugas & kegiatan...',
                );
              }

              if (state.status == TaskListStatus.error) {
                return AppErrorState(
                  message: state.errorMessage ?? 'Data belum berhasil dimuat.',
                  onRetry: controller.load,
                );
              }

              final officerName = state.user?.fullName ?? 'Pengguna';
              final agencyName =
                  state.user?.instansiName ?? 'Instansi tidak diketahui';

              return Column(
                children: [
                  // Filter Chips
                  _buildFilterChips(context, controller),

                  // Content List
                  Expanded(
                    child: state.tasks.isEmpty
                        ? RefreshIndicator(
                            onRefresh: controller.load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                AppEmptyState(
                                  icon: Icons.assignment_outlined,
                                  title:
                                      state.selectedFilter == TaskListFilter.all
                                      ? 'Belum ada tugas aktif'
                                      : 'Tidak ada tugas "${state.selectedFilter.label}"',
                                  message:
                                      state.selectedFilter == TaskListFilter.all
                                      ? 'Tugas atau kegiatan baru akan muncul di sini.'
                                      : 'Pilih filter lain untuk melihat tugas yang tersedia.',
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
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
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    TaskListController controller,
  ) {
    final colors = context.tulapColors;

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TaskListFilter.values.map((filter) {
            final isSelected = controller.state.selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter.label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: colors.surfaceElevated,
                selectedColor: colors.primary,
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                onSelected: (_) => controller.setFilter(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openTaskDetail(
    BuildContext context, {
    required String taskId,
    required String officerName,
    required String agencyName,
  }) async {
    await Navigator.of(context).push(
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

    // Refresh data saat kembali dari TaskDetailPage
    if (context.mounted) {
      context.read<TaskListController>().load();
    }
  }
}

class _TaskListCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const _TaskListCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progressPercent = (task.checklistProgress * 100).toInt();
    final colors = context.tulapColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris 1: Kode / ID + Sync Badge + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            task.taskCode,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.syncStatus == 'LOCAL_ONLY') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.iconSoftBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 11,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Lokal',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusBanner(status: task.status),
                ],
              ),
              const SizedBox(height: 8),

              // Baris 2: Nama Kegiatan
              Text(
                task.taskName,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Baris 3: Tanggal & Lokasi
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      AppDateFormatter.formatDateRange(
                        task.startDate,
                        task.endDate,
                      ),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      task.destination,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Baris 4: Progress & Dokumentasi
              if (task.checklistItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: task.checklistProgress,
                          backgroundColor: colors.surfaceElevated,
                          color: task.checklistProgress >= 1.0
                              ? colors.success
                              : colors.primary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Checklist: ${task.completedChecklistCount}/${task.checklistItems.length}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        if (task.geotagPhotoCount > 0) ...[
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${task.geotagPhotoCount}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.expenseNoteCount > 0) ...[
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${task.expenseNoteCount}',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],

              // Revision Note Alert
              if (task.status == TaskStatusEntity.revisionNeeded &&
                  task.latestRevisionNote != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Revisi: ${task.latestRevisionNote}',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
