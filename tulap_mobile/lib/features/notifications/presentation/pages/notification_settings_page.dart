import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _kegiatanEnabled = true;
  bool _sinkronisasiEnabled = true;
  bool _notaEnabled = true;
  bool _sistemEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Banner Informasi Integritas
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.iconSoftBlue.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Peringatan penting terkait kegagalan sinkronisasi, validitas bukti, dan integritas data lapangan akan tetap ditampilkan di dalam aplikasi.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Pengaturan Kategori
          _buildSettingsCard(
            title: 'Kategori Notifikasi',
            children: [
              _buildSwitchTile(
                title: 'Notifikasi Kegiatan',
                subtitle: 'Pengingat kegiatan aktif, checklist tugas, dan status verifikasi.',
                icon: Icons.assignment_outlined,
                value: _kegiatanEnabled,
                onChanged: (v) => setState(() => _kegiatanEnabled = v),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Status Sinkronisasi',
                subtitle: 'Pemberitahuan data antrean cloud dan status pengunggahan bukti.',
                icon: Icons.cloud_sync_outlined,
                value: _sinkronisasiEnabled,
                onChanged: (v) => setState(() => _sinkronisasiEnabled = v),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Nota & Pengeluaran',
                subtitle: 'Hasil pemrosesan OCR struk dan pemeriksaan nominal nota.',
                icon: Icons.receipt_long_outlined,
                value: _notaEnabled,
                onChanged: (v) => setState(() => _notaEnabled = v),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Informasi Sistem & Lokasi',
                subtitle: 'Peringatan akurasi GPS, status keamanan akun, dan sesi biometrik.',
                icon: Icons.shield_outlined,
                value: _sistemEnabled,
                onChanged: (v) => setState(() => _sistemEnabled = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.iconSoftBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
