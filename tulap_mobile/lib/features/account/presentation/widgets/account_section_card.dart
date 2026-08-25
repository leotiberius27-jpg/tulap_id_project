import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// AccountSectionCard
/// ----------------------------------------------------------------------
/// Wadah kartu putih dengan rounded corners besar dan shadow halus
/// untuk mengelompokkan baris menu di halaman Akun.
/// ----------------------------------------------------------------------
class AccountSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AccountSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.sectionLabel.copyWith(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
