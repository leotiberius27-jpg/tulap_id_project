import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../location/presentation/pages/location_page.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../sync_queue/presentation/controllers/sync_center_controller.dart';
import '../../../sync_queue/presentation/pages/sync_center_page.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/delete_read_notifications.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_notification_count.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../controllers/notifications_controller.dart';
import 'notification_settings_page.dart';

/// NotificationCenterPage (NotificationsPage)
/// ----------------------------------------------------------------------
/// Pusat Notifikasi Lapangan Resmi Tulap.id:
/// - Offline-first: membaca notifikasi dari SQLite lokal.
/// - Filter Kategori: Semua, Kegiatan, Sinkronisasi, Sistem.
/// - Pengelompokan Berdasarkan Tanggal: Hari Ini, Kemarin, Lebih Lama.
/// - Indikator Unread: soft light-blue tint & blue accent bar.
/// - Deep Link: Aksi cepat menuju Task Detail, Sync Center, Receipt Scanner, Location.
/// - Menu Overflow: Tandai semua dibaca, Hapus yang sudah dibaca, Pengaturan.
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
        deleteReadNotifications: sl<DeleteReadNotifications>(),
        getUnreadNotificationCount: sl<GetUnreadNotificationCount>(),
      ),
      child: _NotificationsView(
        officerName: officerName,
        agencyName: agencyName,
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final String officerName;
  final String agencyName;

  const _NotificationsView({
    required this.officerName,
    required this.agencyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        actions: [
          Consumer<NotificationsController>(
            builder: (context, controller, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'Pilihan',
                onSelected: (val) {
                  switch (val) {
                    case 'mark_all':
                      controller.markAllRead();
                      break;
                    case 'delete_read':
                      _confirmDeleteRead(context, controller);
                      break;
                    case 'settings':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage(),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all',
                    enabled: controller.state.unreadCount > 0,
                    child: const Text('Tandai semua sudah dibaca'),
                  ),
                  const PopupMenuItem(
                    value: 'delete_read',
                    child: Text('Hapus yang sudah dibaca'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Pengaturan notifikasi'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsController>(
        builder: (context, controller, _) {
          final state = controller.state;

          return Column(
            children: [
              // 1. FILTER CATEGORY BAR
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.xs,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        isSelected: state.selectedCategory == null,
                        onTap: () => controller.setCategory(null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Kegiatan',
                        isSelected: state.selectedCategory == NotificationCategory.kegiatan,
                        onTap: () => controller.setCategory(NotificationCategory.kegiatan),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sinkronisasi',
                        isSelected: state.selectedCategory == NotificationCategory.sinkronisasi,
                        onTap: () => controller.setCategory(NotificationCategory.sinkronisasi),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sistem',
                        isSelected: state.selectedCategory == NotificationCategory.sistem,
                        onTap: () => controller.setCategory(NotificationCategory.sistem),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // 2. NOTIFICATION LIST CONTENT
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.status == NotificationsStatus.loading && state.items.isEmpty) {
                      return const AppLoadingView(label: 'Memuat notifikasi...');
                    }

                    if (state.status == NotificationsStatus.error && state.items.isEmpty) {
                      return AppErrorState(
                        message: state.errorMessage ?? 'Notifikasi belum bisa dimuat.',
                        onRetry: controller.load,
                      );
                    }

                    final filtered = state.filteredItems;

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            AppEmptyState(
                              icon: Icons.notifications_none_rounded,
                              title: 'Tidak ada notifikasi',
                              message:
                                  'Informasi penting mengenai kegiatan dan sinkronisasi akan muncul di sini.',
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = _groupNotifications(filtered);

                    return RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final item = grouped[index];
                          if (item is _GroupHeader) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 12,
                                bottom: 8,
                              ),
                              child: Text(
                                item.title.toUpperCase(),
                                style: AppTypography.small.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            );
                          } else if (item is _NotificationItem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _NotificationCard(
                                notification: item.entity,
                                onTap: () => _handleTap(context, controller, item.entity),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteRead(BuildContext context, NotificationsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notifikasi Dibaca'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua notifikasi yang sudah dibaca? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteReadNotifications();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    NotificationsController controller,
    NotificationEntity notification,
  ) {
    controller.markRead(notification.id);

    switch (notification.actionType) {
      case NotificationActionType.openTask:
        final taskId = notification.relatedEntityId;
        if (taskId == null || taskId.isEmpty) {
          _showMissingDataSnackbar(context);
          return;
        }
        if (sl.isRegistered<GetTaskDetail>() &&
            sl.isRegistered<ToggleChecklistItem>() &&
            sl.isRegistered<StartTask>() &&
            sl.isRegistered<SubmitTaskForVerification>() &&
            sl.isRegistered<GetTaskPhotoPreviews>()) {
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
        break;

      case NotificationActionType.openSync:
        if (sl.isRegistered<SyncQueueRepository>() &&
            sl.isRegistered<BackgroundSyncService>()) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<SyncCenterController>(
                create: (_) => SyncCenterController(
                  repository: sl<SyncQueueRepository>(),
                  backgroundSyncService: sl<BackgroundSyncService>(),
                ),
                child: const SyncCenterPage(),
              ),
            ),
          );
        }
        break;

      case NotificationActionType.openReceipt:
        final taskId = notification.relatedEntityId;
        if (taskId == null || taskId.isEmpty) {
          _showMissingDataSnackbar(context);
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptScannerEntryPage(
              taskId: taskId,
            ),
          ),
        );
        break;

      case NotificationActionType.openLocation:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LocationPage(
              taskDestination: notification.message.isNotEmpty
                  ? notification.message
                  : 'Lokasi Penugasan',
            ),
          ),
        );
        break;

      case NotificationActionType.none:
        break;
    }
  }

  void _showMissingDataSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data terkait tidak ditemukan.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<dynamic> _groupNotifications(List<NotificationEntity> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <NotificationEntity>[];
    final yesterdayItems = <NotificationEntity>[];
    final olderItems = <NotificationEntity>[];

    for (final item in items) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (itemDate.isAtSameMomentAs(today)) {
        todayItems.add(item);
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(item);
      } else {
        olderItems.add(item);
      }
    }

    final result = <dynamic>[];
    if (todayItems.isNotEmpty) {
      result.add(_GroupHeader('Hari Ini'));
      result.addAll(todayItems.map((e) => _NotificationItem(e)));
    }
    if (yesterdayItems.isNotEmpty) {
      result.add(_GroupHeader('Kemarin'));
      result.addAll(yesterdayItems.map((e) => _NotificationItem(e)));
    }
    if (olderItems.isNotEmpty) {
      result.add(_GroupHeader('Lebih Lama'));
      result.addAll(olderItems.map((e) => _NotificationItem(e)));
    }
    return result;
  }
}

class _GroupHeader {
  final String title;
  _GroupHeader(this.title);
}

class _NotificationItem {
  final NotificationEntity entity;
  _NotificationItem(this.entity);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : (isDark ? colors.surfaceElevated : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final isDark = context.isDarkMode;
    final config = _iconFor(context, notification);
    final isUnread = !notification.isRead;

    return Semantics(
      button: true,
      label: '${notification.title}, ${notification.message}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isUnread ? colors.unreadCardBg : colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(
                color: isUnread
                    ? colors.primary.withValues(alpha: 0.35)
                    : colors.border.withValues(alpha: 0.6),
                width: isUnread ? 1.2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Contextual Category/Type Icon
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: config.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, size: 20, color: config.foreground),
                ),
                const SizedBox(width: AppSpacing.sm),

                // 2. Title, Body Message, Timestamp, Action
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Unread Indicator Dot
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14.5,
                                fontWeight:
                                    isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: colors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6, top: 4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message Body
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDark ? colors.textSecondary : const Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time + Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: AppTypography.small.copyWith(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          if (notification.actionType == NotificationActionType.openSync)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Sinkronkan',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else if (notification.actionType != NotificationActionType.none)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NotificationIconConfig _iconFor(BuildContext context, NotificationEntity n) {
    final colors = context.tulapColors;
    switch (n.type) {
      case NotificationType.activityRunning:
        return _NotificationIconConfig(
          Icons.pending_actions_rounded,
          colors.primary,
          colors.iconSoftBlue,
        );
      case NotificationType.activityIncomplete:
        return _NotificationIconConfig(
          Icons.rule_folder_outlined,
          colors.warning,
          colors.warningSoft,
        );
      case NotificationType.activityCompleted:
        return _NotificationIconConfig(
          Icons.check_circle_outline_rounded,
          colors.success,
          colors.successSoft,
        );
      case NotificationType.syncPending:
        return _NotificationIconConfig(
          Icons.cloud_upload_outlined,
          colors.warning,
          colors.warningSoft,
        );
      case NotificationType.syncFailed:
        return _NotificationIconConfig(
          Icons.cloud_off_rounded,
          colors.danger,
          colors.dangerSoft,
        );
      case NotificationType.syncCompleted:
        return _NotificationIconConfig(
          Icons.cloud_done_rounded,
          colors.success,
          colors.successSoft,
        );
      case NotificationType.receiptProcessed:
        return _NotificationIconConfig(
          Icons.receipt_long_rounded,
          colors.success,
          colors.successSoft,
        );
      case NotificationType.receiptReviewRequired:
        return _NotificationIconConfig(
          Icons.document_scanner_outlined,
          colors.warning,
          colors.warningSoft,
        );
      case NotificationType.locationPermissionRequired:
      case NotificationType.locationAccuracyWarning:
        return _NotificationIconConfig(
          Icons.location_on_outlined,
          colors.warning,
          colors.warningSoft,
        );
      case NotificationType.securityInfo:
        return _NotificationIconConfig(
          Icons.security_rounded,
          colors.primary,
          colors.iconSoftBlue,
        );
      case NotificationType.systemInfo:
      default:
        return _NotificationIconConfig(
          Icons.notifications_outlined,
          colors.primary,
          colors.iconSoftBlue,
        );
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final hourStr = dateTime.hour.toString().padLeft(2, '0');
    final minuteStr = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    if (itemDate.isAtSameMomentAs(today)) {
      return timeStr;
    } else if (itemDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Kemarin • $timeStr';
    } else {
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
        'Des'
      ];
      final monthStr = months[dateTime.month - 1];
      return '${dateTime.day} $monthStr ${dateTime.year} • $timeStr';
    }
  }
}

class _NotificationIconConfig {
  final IconData icon;
  final Color foreground;
  final Color background;
  _NotificationIconConfig(this.icon, this.foreground, this.background);
}
