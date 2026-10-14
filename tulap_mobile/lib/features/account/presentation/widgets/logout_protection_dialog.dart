import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum LogoutDialogAction {
  cancel,
  syncNow,
  logoutNow,
}

/// LogoutProtectionDialog
/// ----------------------------------------------------------------------
/// Dialog konfirmasi keluar akun dengan perlindungan bukti outbox offline.
/// Tampilan mengikuti pola pop-up "Masuk ke ASN Digital": latar gelap
/// pekat + tombol tutup (X) di pojok kanan atas, kartu terang di tengah
/// berbingkai warna brand, logo Tulap.id besar, judul & subjudul di
/// tengah, kotak info, lalu dua tombol berdampingan (sekunder bergaris
/// di kiri, utama terisi di kanan).
///
/// Jika masih ada foto/nota/catatan yang belum tersinkronisasi, kotak
/// info berubah jadi peringatan dan tombol utamanya jadi "Sinkronkan",
/// dengan opsi "Tetap Keluar" di bawahnya.
/// ----------------------------------------------------------------------
class LogoutProtectionDialog extends StatelessWidget {
  final int pendingCount;

  const LogoutProtectionDialog({super.key, required this.pendingCount});

  static const Color _barrierColor = Color(0xF00B1B2E);

  static Future<LogoutDialogAction?> show(
    BuildContext context, {
    required int pendingCount,
  }) {
    return showGeneralDialog<LogoutDialogAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Keluar dari Akun',
      barrierColor: _barrierColor,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          LogoutProtectionDialog(pendingCount: pendingCount),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final accent = hasPending ? AppColors.warning : AppColors.primary;

    return SafeArea(
      child: Stack(
        children: [
          // Tombol tutup (X) di pojok kanan atas layar
          Positioned(
            top: 12,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).pop(LogoutDialogAction.cancel),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                    semanticLabel: 'Tutup',
                  ),
                ),
              ),
            ),
          ),

          // Kartu dialog di tengah
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 72,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 84,
                          height: 84,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.location_on_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.sectionTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.2,
                            ),
                            children: const [
                              TextSpan(text: 'Tulap'),
                              TextSpan(
                                text: '.id',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasPending
                              ? 'Data Belum Tersinkron'
                              : 'Keluar dari Tulap.id',
                          textAlign: TextAlign.center,
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dokumentasi & Pencatatan Kegiatan Lapangan',
                          textAlign: TextAlign.center,
                          style: AppTypography.small.copyWith(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _InfoBox(hasPending: hasPending, pendingCount: pendingCount),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pop(LogoutDialogAction.cancel),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textPrimary,
                                  minimumSize: const Size.fromHeight(46),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(
                                  hasPending
                                      ? LogoutDialogAction.syncNow
                                      : LogoutDialogAction.logoutNow,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(hasPending ? 'Sinkronkan' : 'Keluar'),
                              ),
                            ),
                          ],
                        ),
                        if (hasPending) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(LogoutDialogAction.logoutNow),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Tetap Keluar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak info di tengah kartu (padanan "Panduan penggunaan MFA" pada
/// referensi) - biru lembut untuk konfirmasi biasa, amber saat masih ada
/// data yang belum tersinkronisasi.
class _InfoBox extends StatelessWidget {
  final bool hasPending;
  final int pendingCount;

  const _InfoBox({required this.hasPending, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final color = hasPending ? AppColors.warning : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.warningSoft : AppColors.infoSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTypography.small.copyWith(
            fontSize: 12.5,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
          children: hasPending
              ? [
                  TextSpan(
                    text: '$pendingCount data belum terkirim. ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Data tetap aman di perangkat ini, tapi sebaiknya '
                        'sinkronkan dulu sebelum keluar atau berganti perangkat.',
                  ),
                ]
              : const [
                  TextSpan(
                    text:
                        'Apakah Anda yakin ingin keluar dari akun ini? Anda perlu ',
                  ),
                  TextSpan(
                    text: 'masuk kembali',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(text: ' untuk mengakses tugas Anda.'),
                ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
