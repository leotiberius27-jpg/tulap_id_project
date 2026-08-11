import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/validate_location_integrity.dart';

/// GpsStatusIndicator
/// ----------------------------------------------------------------------
/// Badge status GPS di top bar kamera, sesuai Bagian 8 & 25 spesifikasi:
///   Hijau  -> "Lokasi Valid"
///   Kuning -> "Memeriksa Lokasi"
///   Merah  -> "Lokasi Tidak Valid"
///
/// Prinsip aksesibilitas (Bagian 26): status TIDAK BOLEH hanya
/// mengandalkan warna - selalu disertai ikon dan teks.
/// ----------------------------------------------------------------------
class GpsStatusIndicator extends StatelessWidget {
  final LocationIntegrityStatus status;

  const GpsStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTypography.small.copyWith(
              color: config.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _GpsStatusConfig _configFor(LocationIntegrityStatus status) {
    switch (status) {
      case LocationIntegrityStatus.valid:
        return _GpsStatusConfig(
          label: 'Lokasi Valid',
          icon: Icons.check_circle,
          foreground: AppColors.success,
          background: Colors.white.withOpacity(0.9),
        );
      case LocationIntegrityStatus.checking:
        return _GpsStatusConfig(
          label: 'Memeriksa Lokasi',
          icon: Icons.gps_not_fixed,
          foreground: AppColors.warning,
          background: Colors.white.withOpacity(0.9),
        );
      case LocationIntegrityStatus.invalid:
        return _GpsStatusConfig(
          label: 'Lokasi Tidak Valid',
          icon: Icons.error,
          foreground: AppColors.danger,
          background: Colors.white.withOpacity(0.9),
        );
    }
  }
}

class _GpsStatusConfig {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  _GpsStatusConfig({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
