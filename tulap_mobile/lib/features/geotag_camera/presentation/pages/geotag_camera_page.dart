import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/mock_location_blocking_modal.dart';
import '../widgets/watermark_overlay.dart';

/// GeotagCameraPage
/// ----------------------------------------------------------------------
/// Layar kamera full-screen sesuai Bagian 8 & 21 spesifikasi:
///   - Top bar: Back, Flash, indikator GPS
///   - Viewport: live camera + watermark overlay
///   - Bottom: gallery preview task ini, tombol capture besar
///   - Setelah capture: Preview dengan CTA "Gunakan Foto" / "Ambil Ulang"
///
/// Halaman ini murni "dumb widget" yang mendengarkan
/// GeotagCameraController - semua business logic ada di domain/data layer.
/// ----------------------------------------------------------------------
class GeotagCameraPage extends StatefulWidget {
  final CameraController cameraController;
  final GeotagCameraController geotagController;
  final String officerName;
  final String agencyName;
  final String taskId;

  const GeotagCameraPage({
    super.key,
    required this.cameraController,
    required this.geotagController,
    required this.officerName,
    required this.agencyName,
    required this.taskId,
  });

  @override
  State<GeotagCameraPage> createState() => _GeotagCameraPageState();
}

class _GeotagCameraPageState extends State<GeotagCameraPage> {
  bool _isFlashOn = false;
  LocationIntegrityStatus? _lastShownInvalidStatus;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeotagCameraController>.value(
      value: widget.geotagController,
      child: Consumer<GeotagCameraController>(
        builder: (context, controller, _) {
          final state = controller.state;

          // Tampilkan modal blocking HANYA sekali per transisi ke status
          // invalid (bukan berulang setiap polling 3 detik), agar tidak
          // mengganggu user dengan modal yang muncul terus-menerus.
          //
          // PENTING: guard ini HANYA di-reset saat status kembali ke
          // `valid` (pengguna benar-benar memperbaiki lokasinya) -
          // BUKAN saat status transit ke `checking` di awal tiap siklus
          // polling. Sebelumnya reset juga terjadi pada `checking`,
          // sehingga tiap 3 detik guard "batal" dan modal baru
          // ditumpuk lagi via showDialog walau user sudah menekan
          // "Saya Mengerti" - membuat modal terlihat tidak bisa
          // ditutup sama sekali (dialog baru selalu muncul lagi dalam
          // hitungan detik, bahkan sistem back button pun tampak tidak
          // berefek karena dialog pengganti sudah terpasang lagi).
          if (state.locationStatus == LocationIntegrityStatus.invalid &&
              _lastShownInvalidStatus != LocationIntegrityStatus.invalid) {
            _lastShownInvalidStatus = LocationIntegrityStatus.invalid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              MockLocationBlockingModal.show(context);
            });
          } else if (state.locationStatus == LocationIntegrityStatus.valid) {
            _lastShownInvalidStatus = null;
          }


          return Scaffold(
            backgroundColor: Colors.black,
            body: state.captureStatus == CaptureViewStatus.previewing
                ? _buildPreview(context, controller)
                : _buildLiveCamera(context, controller, state),
          );
        },
      ),
    );
  }

  Widget _buildLiveCamera(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    return Stack(
      children: [
        // Live camera preview mengisi seluruh layar
        Positioned.fill(child: CameraPreview(widget.cameraController)),

        // Watermark overlay - preview real-time data yang akan dicap
        WatermarkOverlay(
          officerName: widget.officerName,
          agencyName: widget.agencyName,
          taskId: widget.taskId,
          latitude: state.latitude,
          longitude: state.longitude,
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back,
                  semanticLabel: 'Kembali',
                  onTap: () => Navigator.of(context).pop(),
                ),
                GpsStatusIndicator(status: state.locationStatus),
                _CircleIconButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  semanticLabel: _isFlashOn ? 'Matikan flash' : 'Nyalakan flash',
                  onTap: () async {
                    setState(() => _isFlashOn = !_isFlashOn);
                    await widget.cameraController.setFlashMode(
                      _isFlashOn ? FlashMode.torch : FlashMode.off,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom bar - capture button
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Ambil foto',
              enabled: state.isCaptureEnabled,
              child: GestureDetector(
              onTap: state.isCaptureEnabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      controller.onCaptureButtonPressed();
                    }
                  : null,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: state.isCaptureEnabled
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                ),
                child: state.captureStatus == CaptureViewStatus.capturing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : null,
              ),
              ),
            ),
          ),
        ),

        if (state.captureStatus == CaptureViewStatus.error)
          _ErrorBanner(
            message: state.errorMessage ?? 'Gagal mengambil foto. Coba lagi.',
          ),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context,
    GeotagCameraController controller,
  ) {
    final photo = controller.state.lastCapturedPhoto;
    if (photo == null) {
      return const Center(
        child: Text('Foto tidak ditemukan.', style: TextStyle(color: Colors.white)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Image.file(
            File(photo.localFilePath), // Path lokal hasil kompresi
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(AppSpacing.base),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: controller.retakePhoto,
                    child: const Text('Ambil Ulang'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.of(context).pop(photo),
                    child: const Text('Gunakan Foto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      left: AppSpacing.base,
      right: AppSpacing.base,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(
          message,
          style: AppTypography.small.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
