import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';

/// LocationSettingsPage
/// ----------------------------------------------------------------------
/// Menampilkan status izin lokasi platform asli, ketersediaan hardware GPS,
/// target akurasi bukti lapangan, serta tombol untuk membuka pengaturan sistem.
/// ----------------------------------------------------------------------
class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  LocationPermission? _permission;
  bool _serviceEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationState();
  }

  Future<void> _checkLocationState() async {
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2));
      final permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _serviceEnabled = serviceEnabled;
          _permission = permission;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _permissionLabel(LocationPermission? p) {
    if (p == null) return 'Memeriksa...';
    switch (p) {
      case LocationPermission.always:
        return 'Selalu Diizinkan';
      case LocationPermission.whileInUse:
        return 'Diizinkan saat aplikasi digunakan';
      case LocationPermission.denied:
        return 'Ditolak (Perlu Izin)';
      case LocationPermission.deniedForever:
        return 'Ditolak Permanen';
      case LocationPermission.unableToDetermine:
        return 'Belum Ditentukan';
    }
  }

  Color _permissionColor(LocationPermission? p) {
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      return AppColors.success;
    }
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lokasi & GPS'),
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
                    // 1. STATUS HARDWARE & IZIN CARD
                    _buildSectionTitle('STATUS LAYANAN LOKASI'),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildStatusRow(
                            icon: Icons.location_on_outlined,
                            title: 'Izin Akses Lokasi',
                            value: _permissionLabel(_permission),
                            valueColor: _permissionColor(_permission),
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildStatusRow(
                            icon: Icons.gps_fixed_rounded,
                            title: 'Hardware GPS Perangkat',
                            value: _serviceEnabled ? 'Aktif' : 'Nonaktif',
                            valueColor: _serviceEnabled ? AppColors.success : AppColors.danger,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildStatusRow(
                            icon: Icons.track_changes_rounded,
                            title: 'Target Akurasi Lapangan',
                            value: '≤ 15 meter (Tinggi)',
                            valueColor: AppColors.primary,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildStatusRow(
                            icon: Icons.shield_outlined,
                            title: 'Anti-Mock GPS Protection',
                            value: 'Aktif & Terverifikasi',
                            valueColor: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. KEBIJAKAN PRIVASI LOKASI
                    _buildSectionTitle('KEBIJAKAN PENGGUNAAN LOKASI'),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.iconSoftBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Akses Hanya Saat Dokumentasi',
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
                            'Tulap.id HANYA mengakses sensor lokasi pada saat Anda membuka kamera atau merekam koordinat bukti penugasan. Aplikasi TIDAK melacak pergerakan lokasi Anda di latar belakang.',
                            style: AppTypography.small.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 3. ACTION BUKA PENGATURAN PERANGKAT
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Geolocator.openAppSettings();
                          _checkLocationState();
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Buka Pengaturan Izin Perangkat'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
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

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
