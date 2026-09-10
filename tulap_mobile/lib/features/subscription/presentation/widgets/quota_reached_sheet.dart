import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/subscription_page.dart';

/// QuotaReachedSheet
/// ----------------------------------------------------------------------
/// Ditampilkan HANYA saat user menekan "+ Buat Kegiatan" dan kuota bulan
/// ini sudah habis (Bagian 30 dokumen redesign - SANGAT PENTING).
/// Kegiatan yang sudah ada TIDAK PERNAH diblokir oleh sheet ini - hanya
/// pembuatan kegiatan baru. Tidak ada dark pattern: "Nanti Saja" sama
/// mudahnya ditekan dengan "Lihat Paket Tulap".
/// ----------------------------------------------------------------------
class QuotaReachedSheet extends StatelessWidget {
  const QuotaReachedSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuotaReachedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.base),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_off_outlined,
                  color: colors.warning,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kuota kegiatan bulan ini telah digunakan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua kegiatan dan bukti Anda tetap aman. Anda tetap dapat '
              'menyelesaikan pekerjaan yang sudah ada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upgrade paket untuk membuat kegiatan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                  );
                },
                child: const Text('Lihat Paket Tulap'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Nanti Saja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
