import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/account_settings_entity.dart';
import '../../domain/usecases/get_account_settings.dart';
import '../../domain/usecases/save_notification_settings.dart';

/// NotificationSettingsPage
/// ----------------------------------------------------------------------
/// Pengaturan preferensi notifikasi tugas, status antrian sinkronisasi,
/// pengingat kegiatan lapangan, dan pengumuman instansi.
/// ----------------------------------------------------------------------
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  NotificationSettingsEntity _settings = const NotificationSettingsEntity();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final getSettings = sl<GetAccountSettings>();
    final settings = await getSettings.getNotificationSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(NotificationSettingsEntity newSettings) async {
    setState(() => _settings = newSettings);
    final save = sl<SaveNotificationSettings>();
    await save(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('PREFERENSI NOTIFIKASI TUGAS'),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            icon: Icons.assignment_outlined,
                            title: 'Notifikasi Tugas Lapangan',
                            subtitle: 'Pemberitahuan penugasan baru & catatan revisi',
                            value: _settings.taskAlerts,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(taskAlerts: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.sync_rounded,
                            title: 'Status Sinkronisasi Outbox',
                            subtitle: 'Pemberitahuan saat foto/nota berhasil terkirim',
                            value: _settings.syncStatusAlerts,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(syncStatusAlerts: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.alarm_rounded,
                            title: 'Pengingat Batas Waktu Kegiatan',
                            subtitle: 'Pengingat sebelum tenggat waktu penugasan',
                            value: _settings.activityReminders,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(activityReminders: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.campaign_outlined,
                            title: 'Pengumuman & Info Sistem',
                            subtitle: 'Informasi pembaruan aplikasi & instansi',
                            value: _settings.systemAnnouncements,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(systemAnnouncements: val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
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
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.iconSoftBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
