import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// TermsPage
/// ----------------------------------------------------------------------
/// Syarat & ketentuan penggunaan aplikasi Tulap.id untuk dokumentasi
/// dan akuntabilitas penugasan lapangan resmi.
/// ----------------------------------------------------------------------
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Syarat Penggunaan'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                icon: Icons.assignment_turned_in_outlined,
                title: '1. Keaslian Bukti Penugasan',
                content:
                    'Pengguna berkewajiban mengambil foto dokumentasi dan bukti pengeluaran secara faktual langsung dari lokasi pelaksanaan kegiatan. Manipulasi foto, pemalsuan koordinat GPS, atau penggunaan media rekaman pihak ketiga dilarang oleh standar operasional.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.fingerprint,
                title: '2. Akun & Kredensial Pengguna',
                content:
                    'Setiap akun pegawai bersifat personal dan bertanggung jawab atas seluruh rekaman data, catatan penugasan, dan pengajuan LPJ yang dibuat menggunakan akun tersebut.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.history_edu_outlined,
                title: '3. Jejak Audit Digital (Audit Trail)',
                content:
                    'Seluruh aktivitas pembuatan, pengubahan, dan verifikasi tugas terekam dalam timeline kronologis dan jejak audit digital yang tidak dapat diubah (immutable).',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.storage_outlined,
                title: '4. Kepemilikan & Kerahasiaan Data',
                content:
                    'Data dokumentasi penugasan merupakan arsip resmi instansi pemerintah/organisasi terkait dan dilindungi sesuai ketentuan tata kelola data publik.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTypography.small.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
