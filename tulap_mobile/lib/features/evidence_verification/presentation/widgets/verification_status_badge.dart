import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';

class VerificationStatusBadge extends StatelessWidget {
  final EvidenceVerificationStatus status;
  final double fontSize;
  final EdgeInsets padding;

  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;

    switch (status) {
      case EvidenceVerificationStatus.verified:
        bgColor = AppColors.successSoft;
        textColor = AppColors.success;
        icon = Icons.verified_rounded;
        break;
      case EvidenceVerificationStatus.synced:
        bgColor = AppColors.iconSoftBlue;
        textColor = AppColors.primary;
        icon = Icons.cloud_done_rounded;
        break;
      case EvidenceVerificationStatus.reviewRequired:
        bgColor = AppColors.warningSoft;
        textColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case EvidenceVerificationStatus.integrityFailed:
        bgColor = AppColors.dangerSoft;
        textColor = AppColors.danger;
        icon = Icons.gpp_bad_rounded;
        break;
      case EvidenceVerificationStatus.recorded:
        bgColor = AppColors.iconSoftBlue;
        textColor = AppColors.primaryHover;
        icon = Icons.lock_clock_rounded;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.labelIndonesian,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
