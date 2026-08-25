import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HelpSupportPage
/// ----------------------------------------------------------------------
/// Pusat panduan dan bantuan operasional lapangan bagi pegawai Tulap.id:
/// Kamera Geotag, Lokasi GPS, Sinkronisasi Outbox, Tugas & LPJ, Nota OCR, dan Akun.
/// ----------------------------------------------------------------------
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bantuan & Dukungan'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // 1. HERO PANDUAN
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.iconSoftBlue,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Bantuan Lapangan',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panduan praktis penggunaan aplikasi saat bertugas di lokasi kegiatan.',
                          style: AppTypography.small.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. FAQ TOPICS
            _buildFaqSection(
              title: 'KAMERA & DOKUMENTASI',
              items: const [
                _FaqItem(
                  question: 'Bagaimana cara mengambil foto bukti yang sah?',
                  answer: 'Buka menu Kamera Geotag, pastikan indikator GPS berwarna hijau (akurasi ≤ 15m), arahkan kamera ke objek penugasan, lalu tekan tombol rana. Watermark alamat, koordinat, dan QR code akan terpatri otomatis pada foto.',
                ),
                _FaqItem(
                  question: 'Mengapa tombol shutter kamera terkunci?',
                  answer: 'Tombol shutter terkunci sementara apabila akurasi sinyal GPS perangkat melebihi 15 meter untuk mencegah bukti ditolak oleh verifikator. Cari area terbuka agar sinyal satelit GPS lebih kuat.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildFaqSection(
              title: 'LOKASI & GPS',
              items: const [
                _FaqItem(
                  question: 'Apakah Tulap.id dapat dipakai tanpa internet?',
                  answer: 'Ya. GPS satelit tetap berfungsi tanpa koneksi internet. Foto dan koordinat akan disimpan ke penyimpanan lokal offline dan otomatis disinkronkan saat ponsel terhubung ke jaringan.',
                ),
                _FaqItem(
                  question: 'Apa yang terjadi jika memakai Fake GPS / Mock Location?',
                  answer: 'Sistem keamanan Tulap.id memiliki deteksi anti-mock GPS aktif. Foto yang diambil dengan lokasi palsu akan otomatis ditandai tidak valid dan ditolak oleh verifikator.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildFaqSection(
              title: 'SINKRONISASI OUTBOX',
              items: const [
                _FaqItem(
                  question: 'Bagaimana cara mengirim data antrian yang tertunda?',
                  answer: 'Buka menu "Data & Sinkronisasi" lalu pilih "Status Sinkronisasi". Tekan tombol "Kirim Semua" saat ponsel Anda sudah memiliki koneksi internet yang stabil.',
                ),
                _FaqItem(
                  question: 'Apakah data saya aman jika keluar aplikasi?',
                  answer: 'Sangat aman. Seluruh data bukti tersimpan dalam basis data SQLite terenkripsi di ponsel Anda sampai proses upload ke server berhasil diverifikasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildFaqSection(
              title: 'NOTA & SCAN OCR',
              items: const [
                _FaqItem(
                  question: 'Bagaimana cara scan nota pengeluaran?',
                  answer: 'Buka menu "Nota" pada Aksi Cepat, posisikan struk belanja di dalam kotak pemindaian dengan pencahayaan cukup. Mesin OCR akan membaca total nominal dan tanggal struk secara otomatis.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection({
    required String title,
    required List<_FaqItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.sectionLabel.copyWith(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            child: Column(
              children: items.map((item) {
                return ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    item.question,
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        item.answer,
                        style: AppTypography.small.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
