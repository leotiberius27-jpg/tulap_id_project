import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// AboutTulapPage
/// ----------------------------------------------------------------------
/// Halaman tentang aplikasi Tulap.id: logo resmi, versi aplikasi,
/// deskripsi platform dokumentasi kegiatan lapangan, dan standar teknologi.
/// ----------------------------------------------------------------------
class AboutTulapPage extends StatelessWidget {
  const AboutTulapPage({super.key});

  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tentang Tulap.id'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // 1. LOGO & BRAND
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tulap.id',
                style: AppTypography.pageTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.iconSoftBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Versi $appVersion (Build $buildNumber)',
                  style: AppTypography.small.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. DESKRIPSI PRODUK
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tulap.id membantu dokumentasi dan pencatatan kegiatan lapangan agar lebih terstruktur, mudah ditelusuri, dan tersimpan dengan baik.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    _buildTechRow(
                      icon: Icons.offline_bolt_outlined,
                      title: 'Offline-First Architecture',
                      subtitle: 'Penyimpanan lokal SQLite & Sinkronisasi Outbox',
                    ),
                    const SizedBox(height: 10),
                    _buildTechRow(
                      icon: Icons.shield_outlined,
                      title: 'Bukti Geotag Anti-Manipulasi',
                      subtitle: 'SHA-256 Checksum, Anti-Mock GPS & Watermark QR',
                    ),
                    const SizedBox(height: 10),
                    _buildTechRow(
                      icon: Icons.document_scanner_outlined,
                      title: 'On-Device OCR Nota',
                      subtitle: 'Ekstraksi nilai transaksi pengeluaran otomatis',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. COPYRIGHT
              Text(
                '© 2026 Tulap.id. Seluruh hak cipta dilindungi.',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.iconSoftBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.small.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
