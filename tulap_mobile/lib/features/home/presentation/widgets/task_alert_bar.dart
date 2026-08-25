import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// TaskAlertBar
/// ----------------------------------------------------------------------
/// Banner compact perhatian tugas (tinggi ~52–58dp):
/// "⚠ 2 tugas perlu perhatian hari ini  →"
/// ----------------------------------------------------------------------
class TaskAlertBar extends StatelessWidget {
  final int urgentCount;
  final VoidCallback onTap;

  const TaskAlertBar({
    super.key,
    required this.urgentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (urgentCount <= 0) return const SizedBox.shrink();
    final colors = context.tulapColors;
    final isDark = context.isDarkMode;
    final alertTextColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF9A3412);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colors.warningSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.warning.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colors.warning,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$urgentCount tugas perlu perhatian hari ini',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: alertTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: alertTextColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
