import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HeroHomeHeader
/// ----------------------------------------------------------------------
/// Header hero gradien navy Beranda - memakai token `heroGradientStart/
/// End` dan gaya teks `hero*` yang sudah ada di design system (sebelumnya
/// terdefinisi tapi tidak dipakai layar mana pun), sesuai arah redesain
/// terbaru yang mengadopsi pola "hero header" ala aplikasi referensi:
/// sapaan + identitas pegawai + notifikasi dalam satu panel besar
/// melengkung di bagian bawah (AppRadius.hero), bukan top bar polos.
/// ----------------------------------------------------------------------
class HeroHomeHeader extends StatelessWidget {
  final String fullName;
  final String agencyName;
  final int pendingSyncCount;
  final bool isOffline;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationTap;

  const HeroHomeHeader({
    super.key,
    required this.fullName,
    required this.agencyName,
    required this.pendingSyncCount,
    required this.isOffline,
    required this.onNotificationTap,
    this.hasUnreadNotifications = false,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.hero),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 26,
                    height: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('TULAP.ID', style: AppTypography.brandTitle),
                const Spacer(),
                _SyncPill(pendingCount: pendingSyncCount, isOffline: isOffline),
                const SizedBox(width: AppSpacing.sm),
                _NotificationButton(
                  onTap: onNotificationTap,
                  showDot: hasUnreadNotifications,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('$_greeting,', style: AppTypography.heroGreeting),
            const SizedBox(height: 2),
            Text(
              fullName,
              style: AppTypography.heroName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    agencyName,
                    style: AppTypography.heroSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  final int pendingCount;
  final bool isOffline;

  const _SyncPill({required this.pendingCount, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final hasIssue = isOffline || pendingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasIssue ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
            size: 13,
            color: Colors.white,
          ),
          if (hasIssue) ...[
            const SizedBox(width: 4),
            Text(
              '$pendingCount',
              style: AppTypography.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool showDot;

  const _NotificationButton({required this.onTap, required this.showDot});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifikasi',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 19,
              ),
              if (showDot)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
