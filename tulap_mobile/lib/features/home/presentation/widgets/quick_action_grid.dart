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
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Foto',
            onTap: onFotoKegiatan,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Nota',
            onTap: onScanNota,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            onTap: onLokasi,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.description_outlined,
            label: 'LPJ',
            onTap: onLihatLpj,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: isEnabled ? AppColors.action : AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
