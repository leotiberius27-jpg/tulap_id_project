import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// AccountMenuRow
/// ----------------------------------------------------------------------
/// Baris menu modular dalam section card halaman Akun.
/// Memiliki icon dengan soft-color container, judul, subtitle opsional,
/// trailing status/switch/chevron, dan touch target >= 48dp yang nyaman.
/// ----------------------------------------------------------------------
class AccountMenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const AccountMenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final effectiveIconColor = iconColor ?? colors.primary;
    final effectiveIconBg = iconBgColor ?? colors.iconSoftBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: effectiveIconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTypography.small.copyWith(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (trailing != null)
                    trailing!
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: AppSpacing.base),
            child: Divider(height: 1, color: colors.border),
          ),
      ],
    );
  }
}
