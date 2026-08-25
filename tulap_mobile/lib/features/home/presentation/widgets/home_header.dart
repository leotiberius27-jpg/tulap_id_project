import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';

/// HomeHeader
/// ----------------------------------------------------------------------
/// Header Beranda Final Tulap.id:
/// - Logo Tulap.id di sisi kiri (44-48dp)
/// - Sapaan waktu dinamis (pagi/siang/sore/malam) berdasarkan jam lokal
/// - Nama user dinamis dengan flexShrink & ellipsis aman untuk nama panjang
/// - Tombol notifikasi ber-badge & avatar profil pengguna
/// - Menghapus teks "Tulap.id / Tugas Lapangan" sesuai arahan spesifikasi
/// ----------------------------------------------------------------------
class HomeHeader extends StatelessWidget {
  final String fullName;
  final String agencyName;
  final String? avatarUrl;
  final int unreadNotificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    required this.fullName,
    required this.agencyName,
    this.avatarUrl,
    this.unreadNotificationCount = 0,
    required this.onNotificationTap,
    this.onProfileTap,
  });

  String get _dynamicGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore,';
    } else {
      return 'Selamat malam,';
    }
  }

  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final colors = context.tulapColors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : AppSpacing.base,
        mediaQuery.padding.top + AppSpacing.sm,
        isSmallScreen ? 12 : AppSpacing.base,
        AppSpacing.sm,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Logo Tulap.id
          Container(
            width: isSmallScreen ? 38 : 46,
            height: isSmallScreen ? 38 : 46,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.task_alt_rounded,
                color: colors.primary,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : AppSpacing.md),

          // 2. Greeting & Nama User Dinamis
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dynamicGreeting,
                  style: AppTypography.small.copyWith(
                    fontSize: isSmallScreen ? 12.5 : 14,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: isSmallScreen ? 19 : 23,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : AppSpacing.sm),

          // 3. Tombol Notifikasi dengan Badge
          _HeaderIconButton(
            onTap: onNotificationTap,
            icon: Icons.notifications_outlined,
            badgeCount: unreadNotificationCount,
            size: isSmallScreen ? 38 : 42,
            tooltip: 'Notifikasi',
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),

          // 4. Avatar Profil Pengguna
          UserAvatar(
            fullName: fullName,
            photoUrl: avatarUrl,
            size: isSmallScreen ? 38 : 42,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final int badgeCount;
  final double size;
  final String tooltip;

  const _HeaderIconButton({
    required this.onTap,
    required this.icon,
    this.badgeCount = 0,
    this.size = 42,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: colors.textPrimary,
                size: size > 40 ? 22 : 19,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
