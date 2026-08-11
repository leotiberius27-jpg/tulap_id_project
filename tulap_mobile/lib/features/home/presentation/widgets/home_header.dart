import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HomeHeader
/// ----------------------------------------------------------------------
/// Sesuai Bagian 11.1 & wireframe Bagian 13: logo, sapaan berdasarkan
/// waktu, nama & instansi pegawai, ikon notifikasi, avatar.
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_greeting, $fullName', style: AppTypography.sectionTitle),
              const SizedBox(height: 2),
              Text(agencyName, style: AppTypography.small),
            ],
          ),
        ),
        const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
            style: AppTypography.body.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
