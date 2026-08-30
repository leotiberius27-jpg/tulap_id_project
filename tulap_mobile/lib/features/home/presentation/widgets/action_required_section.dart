import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/action_required_entity.dart';

class ActionRequiredSection extends StatelessWidget {
  final List<ActionRequiredEntity> actionItems;
  final ValueChanged<ActionRequiredEntity>? onItemTap;

  const ActionRequiredSection({
    super.key,
    required this.actionItems,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (actionItems.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              const Text(
                'Perlu Perhatian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${actionItems.length} tindakan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...actionItems.map((item) => _buildActionCard(context, item, isDark)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ActionRequiredEntity item,
    bool isDark,
  ) {
    Color cardColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (item.severity) {
      case ActionRequiredSeverity.danger:
        cardColor = isDark
            ? const Color(0xFF331515)
            : const Color(0xFFFEF2F2);
        borderColor = AppColors.danger.withValues(alpha: 0.3);
        iconColor = AppColors.danger;
        icon = Icons.error_outline_rounded;
        break;
      case ActionRequiredSeverity.info:
        cardColor = isDark
            ? const Color(0xFF132338)
            : const Color(0xFFF0F9FF);
        borderColor = AppColors.primary.withValues(alpha: 0.3);
        iconColor = AppColors.primary;
        icon = Icons.info_outline_rounded;
        break;
      case ActionRequiredSeverity.warning:
      default:
        cardColor = isDark
            ? const Color(0xFF302511)
            : const Color(0xFFFFFBEB);
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        iconColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onItemTap?.call(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: iconColor.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
