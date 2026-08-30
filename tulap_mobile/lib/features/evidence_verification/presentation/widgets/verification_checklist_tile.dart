import 'package:flutter/material.dart';

enum CheckState {
  pass,
  warning,
  fail;

  Color get color {
    switch (this) {
      case CheckState.pass:
        return const Color(0xFF10B981);
      case CheckState.warning:
        return const Color(0xFFF59E0B);
      case CheckState.fail:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case CheckState.pass:
        return Icons.check_circle_rounded;
      case CheckState.warning:
        return Icons.warning_rounded;
      case CheckState.fail:
        return Icons.cancel_rounded;
    }
  }
}

class VerificationChecklistTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final CheckState state;
  final Widget? trailing;
  final VoidCallback? onTap;

  const VerificationChecklistTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.state,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: state.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.icon,
                    color: state.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
