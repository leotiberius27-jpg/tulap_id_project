import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// CompactSyncBar (Sync Status)
/// ----------------------------------------------------------------------
/// Banner status sinkronisasi data compact (tinggi ~56–66dp):
/// "☁ 2 data menunggu dikirim     Lihat Data →"
/// ----------------------------------------------------------------------
class CompactSyncBar extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final bool allSynced;
  final bool isSyncing;
  final VoidCallback onViewData;

  const CompactSyncBar({
    super.key,
    required this.isOffline,
    required this.pendingCount,
    required this.allSynced,
    required this.isSyncing,
    required this.onViewData,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color iconColor;
    Color bgColor;
    Color borderColor;

    if (isSyncing) {
      label = 'Sedang menyinkronkan data...';
      icon = Icons.sync_rounded;
      iconColor = AppColors.action;
      bgColor = AppColors.iconSoftBlue;
      borderColor = AppColors.action.withValues(alpha: 0.3);
    } else if (isOffline) {
      label = pendingCount > 0
          ? '$pendingCount data tersimpan offline'
          : 'Mode offline (Menunggu koneksi)';
      icon = Icons.cloud_off_outlined;
      iconColor = AppColors.warning;
      bgColor = AppColors.warningSoft;
      borderColor = AppColors.warning.withValues(alpha: 0.35);
    } else if (pendingCount > 0) {
      label = '$pendingCount data menunggu dikirim';
      icon = Icons.cloud_upload_outlined;
      iconColor = AppColors.action;
      bgColor = AppColors.iconSoftBlue;
      borderColor = AppColors.action.withValues(alpha: 0.3);
    } else {
      label = 'Semua data tersinkron';
      icon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.success;
      bgColor = AppColors.successSoft;
      borderColor = AppColors.success.withValues(alpha: 0.3);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewData,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: iconColor == AppColors.warning
                          ? const Color(0xFF9A3412)
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Data',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: iconColor == AppColors.warning
                            ? const Color(0xFF9A3412)
                            : AppColors.action,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: iconColor == AppColors.warning
                          ? const Color(0xFF9A3412)
                          : AppColors.action,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
