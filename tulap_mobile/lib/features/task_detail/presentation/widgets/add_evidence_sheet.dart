import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// AddEvidenceSheet
/// ----------------------------------------------------------------------
/// Bottom sheet "Tambah Bukti" - dipanggil dari FAB Detail Tugas. Hanya
/// menampilkan DUA opsi yang benar-benar sudah terhubung ke fitur nyata
/// (Foto Kegiatan, Scan Nota) - TIDAK menambahkan opsi "Dokumen"/
/// "Catatan" seperti pola generik aplikasi referensi, karena Tulap.id
/// belum punya modul unggah dokumen bebas maupun catatan lapangan bebas
/// di luar checklist. Menambah tombol yang tidak terhubung ke apa pun
/// akan jadi dead-end palsu, melanggar prinsip "tidak pernah ada tombol
/// tanpa aksi nyata".
/// ----------------------------------------------------------------------
Future<String?> showAddEvidenceSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => const _AddEvidenceSheetContent(),
  );
}

class _AddEvidenceSheetContent extends StatelessWidget {
  const _AddEvidenceSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text('Tambah Bukti', style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(
              'Pilih jenis bukti yang ingin ditambahkan untuk tugas ini.',
              style: AppTypography.bodySecondary.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            _EvidenceOption(
              icon: Icons.camera_alt_outlined,
              iconBackground: AppColors.iconSoftBlue,
              title: 'Foto Kegiatan',
              subtitle: 'Ambil foto dengan geotag & watermark resmi.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop('foto');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _EvidenceOption(
              icon: Icons.receipt_long_outlined,
              iconBackground: AppColors.iconSoftCyan,
              title: 'Scan Nota',
              subtitle: 'Pindai struk/nota belanja otomatis (OCR).',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop('nota');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceOption extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EvidenceOption({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.action, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.small),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
