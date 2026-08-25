import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// PrivacyPage
/// ----------------------------------------------------------------------
/// Kebijakan privasi resmi Tulap.id terkait penggunaan kamera, data lokasi,
/// integritas bukti digital, penyimpanan offline, dan sinkronisasi server.
/// ----------------------------------------------------------------------
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
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
                icon: Icons.shield_outlined,
                title: 'Komitmen Perlindungan Data',
                content:
                    'Tulap.id dirancang khusus untuk mendukung akuntabilitas dan dokumentasi kegiatan lapangan pegawai. Kami menjamin bahwa seluruh data dikelola secara aman sesuai peraturan perundang-undangan dan tata kelola instansi.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.camera_alt_outlined,
                title: 'Penggunaan Kamera & Foto Bukti',
                content:
                    'Akses kamera hanya digunakan saat Anda secara eksplisit mengambil foto dokumentasi kegiatan lapangan atau memindai struk nota pengeluaran (OCR). Aplikasi tidak pernah mengakses atau merekam kamera di luar sesi dokumentasi tersebut.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.location_on_outlined,
                title: 'Penggunaan Data Lokasi & GPS',
                content:
                    'Koordinat GPS dan nama wilayah hanya direkam pada saat tombol rana kamera ditekan untuk menyematkan watermark geotag bukti penugasan. Tulap.id TIDAK melakukan pelacakan lokasi secara terus-menerus di latar belakang.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.lock_outline,
                title: 'Keamanan & Enkripsi Sesi',
                content:
                    'Token otentikasi (JWT) disimpan di penyimpanan aman sistem operasi (Encrypted SharedPreferences / Keychain). Kredensial tidak pernah disimpan dalam format teks biasa.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCard(
                icon: Icons.cloud_sync_outlined,
                title: 'Sinkronisasi Cloud Terenkripsi',
                content:
                    'Pengiriman bukti lapangan dan laporan outbox menuju peladen pusat menggunakan protokol HTTPS dengan enkripsi TLS 1.3 serta validasi checksum integritas berkas SHA-256.',
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
