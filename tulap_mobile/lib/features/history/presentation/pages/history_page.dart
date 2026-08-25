import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../controllers/history_controller.dart';

/// HistoryPage (Riwayat Tugas)
/// ----------------------------------------------------------------------
/// Tab "Riwayat" di bottom navigation:
/// - Pencarian realtime berdasarkan judul, kode tugas, lokasi
/// - Filter chips periode (Hari Ini, Minggu Ini, Bulan Ini) & status
/// - Ringkasan metrik riwayat (Total Disetujui, Foto Geotag, Nota)
/// - Kartu riwayat komprehensif dengan tanggal, status, dan bukti
/// ----------------------------------------------------------------------
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Tugas'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<HistoryController>(
          builder: (context, controller, _) {
            final state = controller.state;

            if (state.status == HistoryStatus.loading &&
                state.allTasks.isEmpty) {
              return const AppLoadingView(label: 'Memuat riwayat tugas...');
            }

            if (state.status == HistoryStatus.error && state.allTasks.isEmpty) {
              return AppErrorState(
                message: state.errorMessage ?? 'Riwayat belum berhasil dimuat.',
                onRetry: controller.load,
              );
            }

            final officerName = state.user?.fullName ?? 'Pengguna';
            final agencyName =
                state.user?.instansiName ?? 'Instansi tidak diketahui';

            return RefreshIndicator(
              onRefresh: controller.load,
              color: colors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Search Bar & Filter Header
                  SliverToBoxAdapter(
                    child: Container(
                      color: colors.surface,
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 12 : AppSpacing.base,
                        AppSpacing.sm,
                        isSmallScreen ? 12 : AppSpacing.base,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Input
                          _buildSearchBar(controller, isSmallScreen),
                          const SizedBox(height: AppSpacing.sm),
                          // Filter Chips Horizontal Scroll
                          _buildFilterChips(controller),
                        ],
                      ),
                    ),
                  ),

                  // 2. Summary Stats Banner (jika ada data)
                  if (state.allTasks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSummaryMetrics(state, isSmallScreen),
                    ),

                  // 3. Task List or Empty States
                  if (state.allTasks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Center(
                          child: AppEmptyState(
                            icon: Icons.history_rounded,
                            title: 'Belum Ada Riwayat',
                            message:
                                'Tugas yang telah selesai diverifikasi, disetujui, '
                                'atau tuntas akan tercatat otomatis di sini.',
                          ),
                        ),
                      ),
                    )
                  else if (state.filteredTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.iconSoftBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.base),
                              const Text(
                                'Tidak Ada Hasil',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tidak ada tugas yang sesuai dengan filter atau kata kunci pencarian Anda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  controller.clearSearch();
                                  controller.setFilter(HistoryFilter.all);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Reset Filter'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.action,
                                  side: const BorderSide(
                                    color: AppColors.action,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 12 : AppSpacing.base,
                        AppSpacing.sm,
                        isSmallScreen ? 12 : AppSpacing.base,
                        80, // Padding bawah aman dari bottom bar & FAB
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final task = state.filteredTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _HistoryTaskCard(
                              task: task,
                              isSmallScreen: isSmallScreen,
                              onTap: () => _openTaskDetail(
                                context,
                                taskId: task.id,
                                officerName: officerName,
                                agencyName: agencyName,
                              ),
                            ),
                          );
                        }, childCount: state.filteredTasks.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(HistoryController controller, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: controller.setSearchQuery,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Cari tugas, nomor SPPD, atau lokasi...',
          hintStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _searchController.clear();
                    controller.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(HistoryController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: HistoryFilter.values.map((filter) {
          final isSelected = controller.state.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                controller.setFilter(filter);
              },
              labelStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryMetrics(HistoryState state, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : AppSpacing.base,
        AppSpacing.md,
        isSmallScreen ? 12 : AppSpacing.base,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                label: 'Tuntas',
                value: '${state.totalVerifiedCount}',
                color: AppColors.success,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            Container(width: 1, height: 28, color: AppColors.border),
            Expanded(
              child: _buildMetricItem(
                label: 'Foto Bukti',
                value: '${state.totalGeotagPhotos}',
                color: AppColors.primary,
                icon: Icons.camera_alt_outlined,
              ),
            ),
            Container(width: 1, height: 28, color: AppColors.border),
            Expanded(
              child: _buildMetricItem(
                label: 'Nota SPPD',
                value: '${state.totalExpenseNotes}',
                color: const Color(0xFF0284C7),
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

class _HistoryTaskCard extends StatelessWidget {
  final TaskEntity task;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _HistoryTaskCard({
    required this.task,
    required this.isSmallScreen,
    required this.onTap,
  });

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final sm = (start.month >= 1 && start.month <= 12)
        ? months[start.month - 1]
        : '';
    final em = (end.month >= 1 && end.month <= 12) ? months[end.month - 1] : '';

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day} $sm ${start.year}';
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} $sm ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day} $sm - ${end.day} $em ${start.year}';
    } else {
      return '${start.day} $sm ${start.year} - ${end.day} $em ${end.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = _formatDateRange(task.startDate, task.endDate);
    final hasRevisionNote =
        task.latestRevisionNote != null &&
        task.latestRevisionNote!.trim().isNotEmpty;
    final colors = context.tulapColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 12 : AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Code & Date + Status Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            task.taskCode,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusBanner(status: task.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                task.taskName,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: isSmallScreen ? 15 : 16.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Destination
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.destination,
                      style: AppTypography.small.copyWith(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Divider
              Container(
                height: 1,
                color: colors.border.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Evidence Badges Row with Wrap protection
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildEvidenceChip(
                          icon: Icons.camera_alt_outlined,
                          label: '${task.geotagPhotoCount} Foto',
                          color: colors.primary,
                          bgColor: colors.iconSoftBlue,
                        ),
                        _buildEvidenceChip(
                          icon: Icons.receipt_long_outlined,
                          label: '${task.expenseNoteCount} Nota',
                          color: colors.action,
                          bgColor: colors.iconSoftCyan,
                        ),
                        if (task.checklistItems.isNotEmpty)
                          _buildEvidenceChip(
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                '${task.completedChecklistCount}/${task.checklistItems.length}',
                            color: colors.success,
                            bgColor: colors.successSoft,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),

              // Verifier Revision Note Banner (jika ada)
              if (hasRevisionNote) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: task.status == TaskStatusEntity.rejected
                        ? AppColors.dangerSoft
                        : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: task.status == TaskStatusEntity.rejected
                          ? AppColors.danger.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        task.status == TaskStatusEntity.rejected
                            ? Icons.cancel_outlined
                            : Icons.edit_note_rounded,
                        size: 15,
                        color: task.status == TaskStatusEntity.rejected
                            ? AppColors.danger
                            : const Color(0xFF9A3412),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.latestRevisionNote!,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: task.status == TaskStatusEntity.rejected
                                ? AppColors.danger
                                : const Color(0xFF9A3412),
                          ),
                          maxLines: 2,
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

  Widget _buildEvidenceChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
