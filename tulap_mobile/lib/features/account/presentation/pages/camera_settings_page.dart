import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/account_settings_entity.dart';
import '../../domain/usecases/get_account_settings.dart';
import '../../domain/usecases/save_camera_settings.dart';

/// CameraSettingsPage
/// ----------------------------------------------------------------------
/// Pengaturan preferensi visual watermark Kamera Geotag Tulap.id.
/// Fitur keamanan inti (SHA-256, Anti-Mock GPS, Timestamp, Audit Trail)
/// dijelaskan secara transparan dan beroperasi permanen tanpa toggle.
/// ----------------------------------------------------------------------
class CameraSettingsPage extends StatefulWidget {
  const CameraSettingsPage({super.key});

  @override
  State<CameraSettingsPage> createState() => _CameraSettingsPageState();
}

class _CameraSettingsPageState extends State<CameraSettingsPage> {
  CameraSettingsEntity _settings = const CameraSettingsEntity();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final getSettings = sl<GetAccountSettings>();
    final settings = await getSettings.getCameraSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(CameraSettingsEntity newSettings) async {
    setState(() => _settings = newSettings);
    final save = sl<SaveCameraSettings>();
    await save(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kamera & Dokumentasi'),
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
                    // 1. PREFERENSI VISUAL WATERMARK
                    _buildSectionTitle('PREFERENSI TAMPILAN WATERMARK'),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            icon: Icons.location_city_outlined,
                            title: 'Tampilkan Alamat Lokasi',
                            subtitle: 'Nama jalan, kelurahan, dan kecamatan',
                            value: _settings.showAddress,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(showAddress: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.my_location_rounded,
                            title: 'Tampilkan Koordinat & Plus Code',
                            subtitle: 'Latitude, longitude, dan kode lokasi terbuka',
                            value: _settings.showCoordinates,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(showCoordinates: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.qr_code_2_rounded,
                            title: 'Tampilkan QR Code Verifikasi',
                            subtitle: 'QR code bukti digital untuk validasi instan',
                            value: _settings.showQrCode,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(showQrCode: val),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchRow(
                            icon: Icons.photo_size_select_actual_outlined,
                            title: 'Simpan Salinan Watermark HD',
                            subtitle: 'Resolusi optimal ~300KB untuk upload cepat',
                            value: _settings.saveWatermarkedCopy,
                            onChanged: (val) => _updateSettings(
                              _settings.copyWith(saveWatermarkedCopy: val),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. KEAMANAN SISTEM & INTEGRITAS PERMANEN
                    _buildSectionTitle('STANDAR INTEGRITAS BUKTI (PERMANEN)'),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildSecurityTile(
                            icon: Icons.security_rounded,
                            title: 'SHA-256 Checksum Verification',
                            description: 'Menjamin foto tidak mengalami manipulasi piksel pasca-pengambilan.',
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSecurityTile(
                            icon: Icons.link_rounded,
                            title: 'Task ID Cryptographic Binding',
                            description: 'Setiap foto bukti terikat secara kriptografis dengan ID kegiatan resmi.',
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSecurityTile(
                            icon: Icons.gps_off_rounded,
                            title: 'Anti-Mock GPS Protection',
                            description: 'Deteksi aktif aplikasi lokasi palsu dan mock provider di Android/iOS.',
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSecurityTile(
                            icon: Icons.access_time_filled_rounded,
                            title: 'Hardware & Server Timestamp',
                            description: 'Pencatatan waktu akurat berstandar ISO-8601 berbasis jaringan waktu terpercaya.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Standar integritas di atas dikunci secara permanen oleh arsitektur Tulap.id guna menjamin keabsahan bukti lapangan untuk audit dan LPJ.',
                        style: AppTypography.small.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
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

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TERKUNCI',
                        style: AppTypography.small.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.small.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
