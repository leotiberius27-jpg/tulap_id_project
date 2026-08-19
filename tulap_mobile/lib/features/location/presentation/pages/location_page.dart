import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geotag_camera/domain/usecases/validate_location_integrity.dart';
import '../controllers/location_controller.dart';

/// LocationPage (Lokasi)
/// ----------------------------------------------------------------------
/// Layar "Lokasi" mandiri (Bagian 12/29 master prompt) - verifikasi
/// lokasi ringan terkait tugas tertentu, TANPA pelacakan berkelanjutan
/// (Bagian 72). Menampilkan: lokasi tugas (teks alamat dari data tugas
/// - TaskEntity tidak punya koordinat target, jadi "jarak dari lokasi
/// tugas" SENGAJA tidak ditampilkan, bukan direkayasa), lokasi
/// perangkat saat ini, akurasi GPS, dan status validasi - memakai
/// usecase yang SAMA persis dengan indikator GPS di kamera geotag
/// (ValidateLocationIntegrity), bukan logika deteksi baru.
/// ----------------------------------------------------------------------
class LocationPage extends StatelessWidget {
  final String taskDestination;

  const LocationPage({super.key, required this.taskDestination});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocationController>(
      create: (_) => LocationController(
        validateLocationIntegrity: sl<ValidateLocationIntegrity>(),
      ),
      child: _LocationView(taskDestination: taskDestination),
    );
  }
}

class _LocationView extends StatelessWidget {
  final String taskDestination;

  const _LocationView({required this.taskDestination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lokasi')),
      body: SafeArea(
        top: false,
        child: Consumer<LocationController>(
          builder: (context, controller, _) {
            final state = controller.state;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _InfoCard(
                  icon: Icons.flag_outlined,
                  iconBackground: AppColors.iconSoftIndigo,
                  label: 'Lokasi Tugas',
                  value: taskDestination,
                ),
                const SizedBox(height: AppSpacing.md),
                _ValidationStatusCard(state: state),
                if (state.status == LocationCheckStatus.checked) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(
                    icon: Icons.my_location,
                    iconBackground: AppColors.iconSoftBlue,
                    label: 'Lokasi Saat Ini',
                    value:
                        '${state.latitude!.toStringAsFixed(5)}, ${state.longitude!.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(
                    icon: Icons.gps_fixed,
                    iconBackground: AppColors.iconSoftCyan,
                    label: 'Akurasi GPS',
                    value: '± ${state.accuracyMeters!.round()} meter',
                  ),
                ],
                if (state.status == LocationCheckStatus.error) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorNotice(
                    message: state.errorMessage ?? 'Lokasi tidak dapat diperiksa.',
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: state.status == LocationCheckStatus.checking
                      ? null
                      : controller.checkLocation,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Periksa Ulang'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.action, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.small),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationStatusCard extends StatelessWidget {
  final LocationState state;

  const _ValidationStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: config.foreground.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.foreground, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            config.label,
            style: AppTypography.sectionTitle.copyWith(color: config.foreground),
          ),
          if (config.description != null) ...[
            const SizedBox(height: 4),
            Text(
              config.description!,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _configFor(LocationState state) {
    if (state.status == LocationCheckStatus.checking) {
      return _StatusConfig(
        label: 'Memeriksa Lokasi',
        icon: Icons.gps_not_fixed,
        foreground: AppColors.warning,
        background: AppColors.warningSoft,
      );
    }

    if (state.status == LocationCheckStatus.error) {
      return _StatusConfig(
        label: 'Lokasi Tidak Dapat Diperiksa',
        icon: Icons.location_off_outlined,
        foreground: AppColors.textSecondary,
        background: AppColors.background,
      );
    }

    switch (state.integrityStatus) {
      case LocationIntegrityStatus.valid:
        return _StatusConfig(
          label: 'Lokasi Valid',
          icon: Icons.check_circle,
          foreground: AppColors.success,
          background: AppColors.successSoft,
        );
      case LocationIntegrityStatus.checking:
        return _StatusConfig(
          label: 'Memeriksa Lokasi',
          icon: Icons.gps_not_fixed,
          foreground: AppColors.warning,
          background: AppColors.warningSoft,
        );
      case LocationIntegrityStatus.invalid:
      case null:
        return _StatusConfig(
          label: 'Lokasi Tidak Valid',
          icon: Icons.error,
          foreground: AppColors.danger,
          background: AppColors.dangerSoft,
          description:
              'Nonaktifkan lokasi palsu (fake GPS) pada perangkat Anda untuk hasil yang akurat.',
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final String? description;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    this.description,
  });
}

class _ErrorNotice extends StatelessWidget {
  final String message;
  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Text(
        message,
        style: AppTypography.small.copyWith(color: AppColors.danger),
        textAlign: TextAlign.center,
      ),
    );
  }
}
