import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/timeline_event_entity.dart';

/// ActivityTimelineCard
/// ----------------------------------------------------------------------
/// Menampilkan linimasa kronologis kejadian otomatis dalam satu kegiatan.
/// Setiap event (foto, nota, checklist, mulai/selesai) ditampilkan dengan
/// visual node terhubung, waktu kejadian, dan ikon spesifik.
/// ----------------------------------------------------------------------
class ActivityTimelineCard extends StatelessWidget {
  final List<TimelineEventEntity> events;

  const ActivityTimelineCard({super.key, required this.events});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
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
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    return '${dt.day} $m';
  }

  IconData _iconForEventType(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.activityCreated:
        return Icons.add_circle_outline_rounded;
      case TimelineEventType.activityStarted:
        return Icons.play_arrow_rounded;
      case TimelineEventType.locationRecorded:
        return Icons.location_on_outlined;
      case TimelineEventType.photoCaptured:
        return Icons.camera_alt_outlined;
      case TimelineEventType.receiptScanned:
        return Icons.receipt_long_outlined;
      case TimelineEventType.expenseRecorded:
        return Icons.payments_outlined;
      case TimelineEventType.checklistToggled:
        return Icons.check_circle_outline_rounded;
      case TimelineEventType.noteAdded:
        return Icons.edit_note_rounded;
      case TimelineEventType.activityCompleted:
        return Icons.task_alt_rounded;
      case TimelineEventType.syncCompleted:
        return Icons.cloud_done_outlined;
    }
  }

  Color _colorForEventType(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.activityCreated:
      case TimelineEventType.activityStarted:
        return AppColors.primary;
      case TimelineEventType.locationRecorded:
        return const Color(0xFF0284C7);
      case TimelineEventType.photoCaptured:
        return const Color(0xFF2563EB);
      case TimelineEventType.receiptScanned:
      case TimelineEventType.expenseRecorded:
        return const Color(0xFFD97706);
      case TimelineEventType.checklistToggled:
      case TimelineEventType.activityCompleted:
      case TimelineEventType.syncCompleted:
        return AppColors.success;
      case TimelineEventType.noteAdded:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.iconSoftBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Linimasa Kegiatan Otomatis',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Setiap foto, nota, checklist, dan aksi lapangan akan otomatis tercatat kronologis di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border, width: 1),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'LINIMASA KEGIATAN',
                  style: AppTypography.sectionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} kejadian',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final color = _colorForEventType(event.eventType);
              final icon = _iconForEventType(event.eventType);
              final timeStr = _formatTime(event.eventTimestamp);
              final dateStr = _formatDate(event.eventTimestamp);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Waktu
                    SizedBox(
                      width: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Garis & Node Indicator
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Icon(icon, size: 12, color: color),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.border,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Konten Event
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (event.description != null &&
                                event.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                event.description!,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
