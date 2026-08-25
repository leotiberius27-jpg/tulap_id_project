import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import '../widgets/camera_bottom_bar.dart';
import '../widgets/camera_focus_indicator.dart';
import '../widgets/camera_location_card.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/mock_location_blocking_modal.dart';

/// GeotagCameraPage
/// ----------------------------------------------------------------------
/// Layar Geotagged Camera Fullscreen Profesional Tulap.id:
/// - Preview kamera 100% fullscreen (anti-black-bars, no clipping/stretching)
/// - Tap-to-focus & exposure interaktif dengan indikator animasi
/// - Top bar: Navigasi, Status GPS real-time & presisi akurasi, Flash switch
/// - Floating Glass Info Panel: Judul tugas, alamat, koordinat, jam live
/// - Bottom Controls: Galeri task photos, Shutter profesional, Flip kamera
/// - Mode Review & Validasi Integritas Foto setelah capture
/// ----------------------------------------------------------------------
class GeotagCameraPage extends StatefulWidget {
  final CameraController cameraController;
  final GeotagCameraController geotagController;
  final String officerName;
  final String agencyName;
  final String taskId;
  final String? taskName;
  final VoidCallback onFlipCamera;

  const GeotagCameraPage({
    super.key,
    required this.cameraController,
    required this.geotagController,
    required this.officerName,
    required this.agencyName,
    required this.taskId,
    this.taskName,
    required this.onFlipCamera,
  });

  @override
  State<GeotagCameraPage> createState() => _GeotagCameraPageState();
}

class _GeotagCameraPageState extends State<GeotagCameraPage> {
  FlashMode _flashMode = FlashMode.off;
  LocationIntegrityStatus? _lastShownInvalidStatus;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeotagCameraController>.value(
      value: widget.geotagController,
      child: Consumer<GeotagCameraController>(
        builder: (context, controller, _) {
          final state = controller.state;

          // Tampilkan modal blocking HANYA sekali saat transisi ke status invalid
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
                ? _buildPreviewScreen(context, controller)
                : _buildLiveCameraScreen(context, controller, state),
          );
        },
      ),
    );
  }

  // ====================================================================
  // LIVE CAMERA SCREEN (FULLSCREEN VIEWPORT + GLASS OVERLAYS)
  // ====================================================================
  Widget _buildLiveCameraScreen(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // 1. Perhitungan Aspek Rasio Kamera Fullscreen (BoxFit.cover murni)
        var cameraRatio = widget.cameraController.value.aspectRatio;
        // Di orientasi portrait, plugin camera mengembalikan rasio landscape (width/height > 1)
        if (cameraRatio > 1.0) {
          cameraRatio = 1.0 / cameraRatio; // e.g. 720/1280 = 0.5625
        }

        final screenRatio = screenWidth / screenHeight;
        final scale = screenRatio < cameraRatio
            ? (cameraRatio / screenRatio)
            : (screenRatio / cameraRatio);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Live Camera Feed Fullscreen
            ClipRect(
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: AspectRatio(
                      aspectRatio: cameraRatio,
                      child: CameraPreview(widget.cameraController),
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Area Sentuh Tap-to-Focus & Exposure
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTapToFocus(details, screenWidth, screenHeight),
              ),
            ),

            // Layer 3: Indikator Animasi Titik Fokus
            if (state.focusPoint != null)
              CameraFocusIndicator(
                position: state.focusPoint!,
                visible: state.isFocusIndicatorVisible,
              ),

            // Layer 4: Gradien Hitam Atas & Bawah untuk Kontras & Keterbacaan Teks
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 280,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xB3000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 5: Top Bar Kontrol (Back, Status GPS Realtime, Flash)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Kembali
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Kembali',
                        onTap: () => Navigator.of(context).pop(),
                      ),

                      // Badge Status GPS Realtime & Akurasi Numerik
                      GpsStatusIndicator(
                        status: state.locationStatus,
                        tier: state.locationTier,
                        accuracyMeters: state.accuracyMeters,
                      ),

                      // Tombol Flash Mode
                      _CircleIconButton(
                        icon: _resolveFlashIcon(),
                        semanticLabel: 'Pengaturan Flash',
                        onTap: _cycleFlashMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 6: Floating Glass Information Panel + Bottom Controls Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Dark Frosted Glass Location Card
                  CameraLocationCard(
                    taskName:
                        widget.taskName ??
                        'Dokumentasi Tugas #${widget.taskId}',
                    officerName: widget.officerName,
                    agencyName: widget.agencyName,
                    latitude: state.latitude,
                    longitude: state.longitude,
                    accuracyMeters: state.accuracyMeters,
                    address: state.address,
                    currentTime: state.currentTime,
                  ),

                  const SizedBox(height: 8),

                  // Bottom Controls Bar (Gallery, Shutter, Flip Camera)
                  CameraBottomBar(
                    state: state,
                    onCapture: controller.onCaptureButtonPressed,
                    onFlipCamera: widget.onFlipCamera,
                    onLowAccuracyTap: () =>
                        _showLowAccuracyDialog(context, controller, state),
                    taskPhotos: state.taskPhotos,
                  ),
                ],
              ),
            ),

            // Layer 7: Error Banner jika capture gagal
            if (state.captureStatus == CaptureViewStatus.error &&
                state.errorMessage != null)
              Positioned(
                top: 90,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEB991B1B), // Dark Red
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ====================================================================
  // CAPTURED PHOTO REVIEW SCREEN (WITH AUDIT & INTEGRITY BADGES)
  // ====================================================================
  Widget _buildPreviewScreen(
    BuildContext context,
    GeotagCameraController controller,
  ) {
    final photo = controller.state.lastCapturedPhoto;
    if (photo == null) {
      return const Center(
        child: Text(
          'Foto tidak ditemukan.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Gambar Hasil Foto Fullscreen
        Image.file(
          File(photo.localFilePath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),

        // 2. Header Status Bukti Terenkripsi
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xD90F172A),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFF10B981), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Foto Berhasil Diverifikasi • ±${photo.gpsAccuracyMeters.round()}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom Action Buttons (Ambil Ulang & Gunakan Foto)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xF20B132B), Colors.transparent],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Tombol Ambil Ulang
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Ambil Ulang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                          width: 1.5,
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: controller.retakePhoto,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tombol Gunakan Foto
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Gunakan Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006EE6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(photo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // HELPER METHODS (FOCUS, FLASH, OVERRIDE MODAL)
  // ====================================================================
  void _handleTapToFocus(
    TapUpDetails details,
    double screenWidth,
    double screenHeight,
  ) async {
    final localOffset = details.localPosition;
    final normX = (localOffset.dx / screenWidth).clamp(0.0, 1.0);
    final normY = (localOffset.dy / screenHeight).clamp(0.0, 1.0);

    widget.geotagController.showFocusIndicator(localOffset);

    try {
      if (widget.cameraController.value.isInitialized) {
        await widget.cameraController.setFocusPoint(Offset(normX, normY));
        await widget.cameraController.setExposurePoint(Offset(normX, normY));
      }
    } catch (_) {
      // Abaikan jika device tidak support manual focus point
    }
  }

  IconData _resolveFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.torch:
        return Icons.highlight_rounded;
      case FlashMode.always:
      case FlashMode.auto:
        return Icons.flash_on_rounded;
    }
  }

  Future<void> _cycleFlashMode() async {
    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await widget.cameraController.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {}
  }

  void _showLowAccuracyDialog(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    final acc = state.accuracyMeters != null
        ? '±${state.accuracyMeters!.round()}m'
        : 'belum terdeteksi';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_not_fixed_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Akurasi GPS Belum Optimal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Akurasi GPS saat ini ($acc) belum mencapai ambang batas ideal (≤ 15m) untuk bukti audit resmi.\n\nAnda dapat menunggu sinyal satelit terkunci lebih presisi atau tetap mengambil foto dengan catatan kualitas sinyal.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tunggu Sinyal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006EE6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.allowGpsOverride();
                    },
                    child: const Text('Ambil Catatan'),
                  ),
                ),
              ],
            ),
          ],
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
