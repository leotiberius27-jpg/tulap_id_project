import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// QuickActionGrid
/// ----------------------------------------------------------------------
/// "Aksi Cepat" sesuai Bagian 11.1 & wireframe Bagian 13: Foto Kegiatan,
/// Scan Nota, Lokasi, Lihat LPJ. Foto Kegiatan & Scan Nota beroperasi
/// pada tugas aktif (nonaktif jika belum ada tugas aktif, sama seperti
/// evidence action di Detail Tugas yang butuh taskId). Lokasi & Lihat
/// LPJ belum punya layar tujuan di mobile - onTap menampilkan pesan
/// "belum tersedia", mengikuti pola placeholder yang sama seperti yang
/// sebelumnya dipakai tombol Scan Nota di Detail Tugas sebelum entry
/// page-nya dibangun.
///
/// Secara visual tampil sebagai satu panel putih (Bagian 11) dengan ikon
/// dalam lingkaran soft berwarna variasi biru/cyan/teal (Bagian 10) -
/// bukan lagi 4 tombol terpisah berborder.
/// ----------------------------------------------------------------------
class QuickActionGrid extends StatelessWidget {
  final VoidCallback? onFotoKegiatan;
  final VoidCallback? onScanNota;
  final VoidCallback onLokasi;
  final VoidCallback onLihatLpj;

  const QuickActionGrid({
    super.key,
    required this.onFotoKegiatan,
    required this.onScanNota,
    required this.onLokasi,
    required this.onLihatLpj,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowSoft, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Foto',
            iconBackground: AppColors.iconSoftBlue,
            onTap: onFotoKegiatan,
          ),
          _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Nota',
            iconBackground: AppColors.iconSoftCyan,
            onTap: onScanNota,
          ),
          _QuickActionButton(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            iconBackground: AppColors.iconSoftTeal,
            onTap: onLokasi,
          ),
          _QuickActionButton(
            icon: Icons.description_outlined,
            label: 'LPJ',
            iconBackground: AppColors.iconSoftIndigo,
            onTap: onLihatLpj,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBackground;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEnabled ? iconBackground : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isEnabled ? AppColors.action : AppColors.textSecondary, size: 22),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
