import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HomeHeader
/// ----------------------------------------------------------------------
/// Top bar + sapaan Beranda. Kanvas terang (bukan hero biru penuh) sesuai
/// arah desain terbaru: navy dipakai strategis di kartu/aksi, bukan
/// mendominasi seluruh atas layar - agar Beranda terasa lebih ringan dan
/// lapang (referensi gaya project-management app).
/// ----------------------------------------------------------------------
class HomeHeader extends StatelessWidget {
  final String fullName;
  final String agencyName;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.fullName,
    required this.agencyName,
    required this.onNotificationTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Beranda', style: AppTypography.sectionTitle),
              const Spacer(),
              _NotificationButton(onTap: onNotificationTap),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('$_greeting,', style: AppTypography.bodySecondary),
          const SizedBox(height: 2),
          Text(
            fullName,
            style: AppTypography.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.apartment_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  agencyName,
                  style: AppTypography.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifikasi',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
