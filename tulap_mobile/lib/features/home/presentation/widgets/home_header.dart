import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HomeHeader
/// ----------------------------------------------------------------------
/// Hero header Beranda: latar gradient biru institusional, wordmark,
/// notifikasi, sapaan + nama pegawai, instansi, dan avatar. Sesuai
/// Bagian 5 & 19 spesifikasi visual - "premium hero", bukan AppBar datar.
/// Sudut bawah dibuat membulat agar ActiveTaskCard bisa "mengambang" di
/// atasnya (Bagian 6: transisi visual halus).
/// ----------------------------------------------------------------------
class HomeHeader extends StatelessWidget {
  final String fullName;
  final String agencyName;

  const HomeHeader({super.key, required this.fullName, required this.agencyName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        topPadding + AppSpacing.md,
        AppSpacing.base,
        AppSpacing.xxxl + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.hero),
          bottomRight: Radius.circular(AppRadius.hero),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('TULAP.ID', style: AppTypography.brandTitle),
              const Spacer(),
              _HeroIconButton(icon: Icons.notifications_outlined, onTap: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: AppTypography.heroGreeting),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      style: AppTypography.heroName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.apartment_outlined, size: 14, color: Colors.white70),
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
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
