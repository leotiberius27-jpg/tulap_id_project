import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../controllers/notifications_controller.dart';

/// NotificationsPage
/// ----------------------------------------------------------------------
/// Dibuka dari tombol lonceng di HomeHeader (Bagian 11.1 spesifikasi).
/// Bukan tab bottom-nav tersendiri - notifikasi adalah lapisan sekunder
/// di atas Beranda, konsisten dengan mockup wireframe Bagian 13 yang
/// hanya menampilkan ikon lonceng, bukan tab kelima.
/// ----------------------------------------------------------------------
class NotificationsPage extends StatelessWidget {
  final String officerName;
  final String agencyName;

  const NotificationsPage({
    super.key,
    required this.officerName,
    required this.agencyName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsController>(
      create: (_) => NotificationsController(
        getNotifications: sl<GetNotifications>(),
        markNotificationRead: sl<MarkNotificationRead>(),
        markAllNotificationsRead: sl<MarkAllNotificationsRead>(),
      ),
      child: _NotificationsView(officerName: officerName, agencyName: agencyName),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final String officerName;
  final String agencyName;

  const _NotificationsView({required this.officerName, required this.agencyName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Consumer<NotificationsController>(
            builder: (context, controller, _) {
              if (controller.state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: controller.markAllRead,
                child: const Text('Tandai semua dibaca'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<NotificationsController>(
          builder: (context, controller, _) {
            final state = controller.state;

            if (state.status == NotificationsStatus.loading) {
              return const AppLoadingView(label: 'Memuat notifikasi...');
            }

            if (state.status == NotificationsStatus.error) {
              return AppErrorState(
                message: state.errorMessage ?? 'Notifikasi belum bisa dimuat.',
                onRetry: controller.load,
              );
            }

            if (state.items.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    AppEmptyState(
                      icon: Icons.notifications_none,
                      title: 'Belum ada notifikasi',
                      message: 'Pemberitahuan tugas baru dan hasil verifikasi akan muncul di sini.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.base),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final notification = state.items[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () => _handleTap(context, controller, notification),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    NotificationsController controller,
    NotificationEntity notification,
  ) {
    controller.markRead(notification.id);
    if (notification.relatedTaskId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskDetailController>(
          create: (_) => TaskDetailController(
            getTaskDetail: sl<GetTaskDetail>(),
            toggleChecklistItem: sl<ToggleChecklistItem>(),
            startTask: sl<StartTask>(),
            submitForVerification: sl<SubmitTaskForVerification>(),
            taskId: notification.relatedTaskId!,
          ),
          child: TaskDetailPage(officerName: officerName, agencyName: agencyName),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = _iconFor(notification.type);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: const [
              BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: config.background, shape: BoxShape.circle),
                child: Icon(config.icon, size: 18, color: config.foreground),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.action,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notification.body, style: AppTypography.small),
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: AppTypography.small.copyWith(color: AppColors.textSecondary),
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

  _NotificationIconConfig _iconFor(NotificationTypeEntity type) {
    switch (type) {
      case NotificationTypeEntity.taskAssigned:
        return _NotificationIconConfig(Icons.assignment_outlined, AppColors.action, AppColors.iconSoftBlue);
      case NotificationTypeEntity.revisionNeeded:
        return _NotificationIconConfig(Icons.edit_note, AppColors.warning, AppColors.warningSoft);
      case NotificationTypeEntity.taskApproved:
        return _NotificationIconConfig(Icons.verified_outlined, AppColors.success, AppColors.successSoft);
      case NotificationTypeEntity.taskRejected:
        return _NotificationIconConfig(Icons.cancel_outlined, AppColors.danger, AppColors.dangerSoft);
      case NotificationTypeEntity.lpjReady:
        return _NotificationIconConfig(Icons.description_outlined, AppColors.primary, AppColors.iconSoftBlue);
      case NotificationTypeEntity.unknown:
        return _NotificationIconConfig(Icons.notifications_outlined, AppColors.textSecondary, AppColors.background);
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}

class _NotificationIconConfig {
  final IconData icon;
  final Color foreground;
  final Color background;
  _NotificationIconConfig(this.icon, this.foreground, this.background);
}
