import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/assistant_message_entity.dart';

class AssistantCardWidget extends StatelessWidget {
  final AssistantCardEntity card;
  final VoidCallback? onOpen;

  const AssistantCardWidget({
    super.key,
    required this.card,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, badgeColor) = _getTypeVisuals(card.entityType);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badge & Type Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTypeLabel(card.entityType),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (card.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                card.subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),
            // Bottom Info & Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (card.date != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppDateFormatter.formatCompact(card.date!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      if (card.amount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          card.amount!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Buka',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _getTypeVisuals(String entityType) {
    switch (entityType.toUpperCase()) {
      case 'ACTIVITY':
      case 'TASK':
        return (Icons.assignment_outlined, AppColors.primary, AppColors.primary);
      case 'TRAVEL':
        return (Icons.flight_takeoff_outlined, const Color(0xFF0D9488), const Color(0xFF0D9488));
      case 'RECEIPT':
        return (Icons.receipt_long_outlined, const Color(0xFFE65100), const Color(0xFFE65100));
      case 'LPJ':
        return (Icons.description_outlined, const Color(0xFF4F46E5), const Color(0xFF4F46E5));
      case 'EVIDENCE':
        return (Icons.camera_alt_outlined, const Color(0xFF7B1FA2), const Color(0xFF7B1FA2));
      case 'REPORT':
        return (Icons.assessment_outlined, const Color(0xFF0284C7), const Color(0xFF0284C7));
      default:
        return (Icons.folder_outlined, AppColors.primary, AppColors.primary);
    }
  }

  String _formatTypeLabel(String entityType) {
    switch (entityType.toUpperCase()) {
      case 'ACTIVITY':
      case 'TASK':
        return 'KEGIATAN';
      case 'TRAVEL':
        return 'PERJALANAN DINAS';
      case 'RECEIPT':
        return 'NOTA PENGELUARAN';
      case 'LPJ':
        return 'BERKAS LPJ';
      case 'EVIDENCE':
        return 'DOKUMENTASI FOTO';
      case 'REPORT':
        return 'LAPORAN';
      default:
        return entityType.toUpperCase();
    }
  }
}
