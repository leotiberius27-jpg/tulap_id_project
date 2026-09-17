import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import '../../../evidence_gallery/presentation/widgets/geotag_photo_location_card.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import '../controllers/geotag_camera_controller.dart';
import '../widgets/camera_add_text_sheet.dart';
import '../widgets/camera_bottom_bar.dart';
import '../widgets/camera_control_panel.dart';
import '../widgets/camera_focus_indicator.dart';
import '../widgets/camera_grid_overlay.dart';
import '../widgets/camera_level_overlay.dart';
import '../widgets/camera_mode_selector.dart';
import '../widgets/camera_rename_sheet.dart';
import '../widgets/camera_stamp_preview.dart';
import '../widgets/camera_timer_countdown_overlay.dart';
import '../widgets/camera_top_control_bar.dart';
import '../widgets/camera_zoom_controls.dart';
import '../widgets/mock_location_blocking_modal.dart';
import '../widgets/template_selector_sheet.dart';
import 'advanced_camera_settings_page.dart';

/// GeotagCameraPage
/// ----------------------------------------------------------------------
/// Layar Geotagged Camera Fullscreen Profesional Tulap.id (Phase 1-4):
/// - Live camera preview aspect-ratio preserving
/// - Mode FOTO & VIDEO (Audio + Live Duration)
/// - Top Bar: Control Panel, Flash, Rename, GPS, Switch Camera, Settings
/// - Expandable Camera Control Panel (4-baris grid)
/// - Indikator Level Horizon (Waterpass Sensor)
/// - Timer Countdown Shutter (3s, 5s, 10s) dengan animasi berdenyut
/// - Floating Location Stamp Card & Template Selector
/// ----------------------------------------------------------------------
class GeotagCameraPage extends StatefulWidget {
  final CameraController cameraController;
  final GeotagCameraController geotagController;
  final CameraLensDirection currentLensDirection;
  final String officerName;
  final String agencyName;
  final String taskId;
  final String? taskName;
  final VoidCallback onFlipCamera;

  const GeotagCameraPage({
    super.key,
    required this.cameraController,
    required this.geotagController,
    required this.currentLensDirection,
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
  LocationIntegrityStatus? _lastShownInvalidStatus;
  double _baseZoomScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeotagCameraController>.value(
      value: widget.geotagController,
      child: Consumer<GeotagCameraController>(
        builder: (context, controller, _) {
          final state = controller.state;

          // Tampilkan modal blocking HANYA sekali saat transisi ke status invalid (Mock GPS / Root)
          if (state.locationStatus == LocationIntegrityStatus.invalid &&
              _lastShownInvalidStatus != LocationIntegrityStatus.invalid) {
            _lastShownInvalidStatus = LocationIntegrityStatus.invalid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              MockLocationBlockingModal.show(context);
            });
          } else if (state.locationStatus == LocationIntegrityStatus.valid) {
            _lastShownInvalidStatus = null;
          }

          return PopScope(
            canPop: !state.isRecordingVideo,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBackPress(context, controller, state);
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: state.captureStatus == CaptureViewStatus.previewing
                  ? _buildPhotoPreviewScreen(context, controller)
                  : (state.recordedVideoPath != null
                        ? _buildVideoReviewScreen(context, controller, state)
                        : _buildLiveCameraScreen(context, controller, state)),
            ),
          );
        },
      ),
    );
  }

  // ====================================================================
  // LIVE CAMERA SCREEN (FULLSCREEN VIEWPORT + CONTROLS)
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
        if (cameraRatio > 1.0) {
          cameraRatio = 1.0 / cameraRatio; // Portrait e.g. 720/1280
        }

        final screenRatio = screenWidth / screenHeight;
        final scale = screenRatio < cameraRatio
            ? (cameraRatio / screenRatio)
            : (screenRatio / cameraRatio);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Live Camera Feed Fullscreen Layar Penuh Handphone (Edge-to-Edge)
            Positioned.fill(
              child: ClipRect(
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
            ),

            // Layer 2: Area Sentuh Tap-to-Focus, Pinch-to-Zoom, Double-tap Switch Camera, & Tutup Panel
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () {
                  if (!state.isRecordingVideo && !state.isSwitchingCamera) {
                    HapticFeedback.lightImpact();
                    widget.onFlipCamera();
                  }
                },
                onScaleStart: (_) {
                  if (state.isControlPanelOpen) controller.closeControlPanel();
                  _baseZoomScale = state.zoomLevel;
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    final targetZoom = (_baseZoomScale * details.scale)
                        .clamp(state.minZoomLevel, state.maxZoomLevel);
                    controller.setZoomLevel(
                      targetZoom,
                      widget.cameraController,
                    );
                  }
                },
                onTapUp: (details) {
                  if (state.isControlPanelOpen) {
                    controller.closeControlPanel();
                    return;
                  }
                  controller.handleTapToFocus(
                    localOffset: details.localPosition,
                    previewSize: Size(screenWidth, screenHeight),
                    cameraController: widget.cameraController,
                  );
                },
              ),
            ),

            // Layer 3: Grid Overlay 3x3 (Rule of Thirds)
            CameraGridOverlay(visible: state.isGridEnabled),

            // Layer 4: Indikator Level Horizon (Waterpass Sensor)
            CameraLevelOverlay(
              rollDegrees: state.levelDegrees,
              isLevel: state.isLevel,
              visible: state.cameraPreferences.levelEnabled,
            ),

            // Layer 5: Indikator Animasi Titik Fokus (Tulap.id Blue)
            if (state.focusPoint != null &&
                state.cameraPreferences.focusGuideEnabled)
              CameraFocusIndicator(
                position: state.focusPoint!,
                visible: state.isFocusIndicatorVisible,
              ),

            // Layer 6: Kilatan Animasi Putih saat Pengambilan Foto (80-120ms)
            if (state.isFlashAnimationActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: state.isFlashAnimationActive ? 0.7 : 0.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(color: Colors.white),
                  ),
                ),
              ),

            // Layer 7: Gradien Atas & Bawah untuk Keterbacaan Teks
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
              height: 340,
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

            // Layer 8: Top Control Bar (6 Ikon Referensi 01.jpeg)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CameraTopControlBar(
                isControlPanelOpen: state.isControlPanelOpen,
                flashMode: state.flashMode,
                isFlashSupported: state.isFlashSupported,
                isSwitchingCamera: state.isSwitchingCamera,
                isRecording: state.isRecordingVideo,
                locationStatus: state.locationStatus,
                locationTier: state.locationTier,
                accuracyMeters: state.accuracyMeters,
                timerSeconds: state.cameraPreferences.timerSeconds,
                onToggleControlPanel: controller.toggleControlPanel,
                onCycleFlash: () => controller.cycleFlashMode(
                  widget.cameraController,
                  widget.currentLensDirection,
                ),
                onAddText: () => CameraAddTextSheet.show(
                  context,
                  currentCaption: state.caption,
                  onSave: controller.setCustomCaption,
                ),
                onRename: () => CameraRenameSheet.show(
                  context,
                  currentMode: state.cameraPreferences.fileNamingMode,
                  currentPrefix: state.cameraPreferences.customFilePrefix,
                  taskName: widget.taskName ?? widget.taskId,
                  isVideo: state.cameraMode == CameraCaptureMode.video,
                  onSave: (mode, prefix) =>
                      controller.setFileNaming(mode, prefix),
                ),
                onLocationTap: () =>
                    _showLocationDetailsModal(context, controller, state),
                onCycleTimer: controller.cycleTimer,
                onSwitchCamera: widget.onFlipCamera,
                onOpenSettings: () {
                  controller.closeControlPanel();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdvancedCameraSettingsPage(
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Layer 9: Indikator Perekaman Video Live (Pill Merah Berkedip)
            if (state.isRecordingVideo)
              Positioned(
                top: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0F172A),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '● ${state.formattedRecordingDuration}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Layer 10: Quick Zoom Controls & Live Stamp Preview & Mode Selector & Bottom Controls (01.jpeg)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Center Floating Quick Zoom Controls (1x, 2x pill with yellow active bubble from 01.jpeg)
                  Center(
                    child: CameraZoomControls(
                      currentZoom: state.zoomLevel,
                      minZoom: state.minZoomLevel,
                      maxZoom: state.maxZoomLevel,
                      onZoomChanged: (zoom) => controller.setZoomLevel(
                        zoom,
                        widget.cameraController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Floating Live Stamp Card (Google Mini Map + Address + Coordinates + Time + QR)
                  CameraStampPreview(
                    taskName: widget.taskName ?? 'Monitoring Lapangan Tulap.id',
                    officerName: widget.officerName,
                    agencyName: widget.agencyName,
                    latitude: state.latitude,
                    longitude: state.longitude,
                    accuracyMeters: state.accuracyMeters,
                    address: state.address,
                    currentTime: state.currentTime,
                    stampConfig: state.stampConfig,
                  ),
                  const SizedBox(height: 4),

                  // Mode Selector: BAGIKAN FOTO, FOTO, VIDEO, LAPORAN (Pill Kuning 01.jpeg)
                  CameraModeSelector(
                    selectedMode: state.cameraMode,
                    isRecording: state.isRecordingVideo,
                    onModeChanged: controller.setCameraMode,
                  ),
                  const SizedBox(height: 4),

                  // Bottom Action Bar: Pratinjau, Lokasi, Shutter, Default, Template
                  CameraBottomBar(
                    state: state,
                    onCapture: controller.onCaptureButtonPressed,
                    onStartRecording: () =>
                        controller.startVideoRecording(widget.cameraController),
                    onStopRecording: () =>
                        controller.stopVideoRecording(widget.cameraController),
                    onFlipCamera: widget.onFlipCamera,
                    onLowAccuracyTap: () =>
                        _showLowAccuracyDialog(context, controller, state),
                    taskPhotos: state.taskPhotos,
                    onLocationTap: () =>
                        _showLocationDetailsModal(context, controller, state),
                    onPresetTap: () => CameraRenameSheet.show(
                      context,
                      currentMode: state.cameraPreferences.fileNamingMode,
                      currentPrefix: state.cameraPreferences.customFilePrefix,
                      taskName: widget.taskName ?? widget.taskId,
                      isVideo: state.cameraMode == CameraCaptureMode.video,
                      onSave: (mode, prefix) =>
                          controller.setFileNaming(mode, prefix),
                    ),
                    onTemplateTap: () => TemplateSelectorSheet.show(
                      context,
                      controller: controller,
                    ),
                    onOpenGallery: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EvidenceViewerPage(
                            initialEvidenceList: state.taskPhotos,
                            initialIndex: 0,
                            taskId: widget.taskId,
                            taskName: widget.taskName,
                          ),
                        ),
                      ).then((_) => controller.refreshTaskPhotos());
                    },
                  ),
                ],
              ),
            ),

            // Layer 11: Expandable Camera Control Panel (Slide & Fade dari Atas)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              top: state.isControlPanelOpen ? 0 : -440,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: state.isControlPanelOpen ? 1.0 : 0.0,
                child: CameraControlPanel(
                  controller: controller,
                  cameraController: widget.cameraController,
                  currentLensDirection: widget.currentLensDirection,
                  onClose: controller.closeControlPanel,
                ),
              ),
            ),

            // Layer 12: Timer Countdown Overlay (Hitung Mundur 3..2..1)
            if (state.isCountdownActive)
              CameraTimerCountdownOverlay(
                remainingSeconds: state.remainingTimerSeconds,
                onCancel: controller.cancelTimerCountdown,
              ),
          ],
        );
      },
    );
  }

  // ====================================================================
  // CAPTURED PHOTO REVIEW SCREEN
  // ====================================================================
  Widget _buildPhotoPreviewScreen(
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
        // PENTING - sengaja pakai `originalFilePath` (foto mentah SEBELUM
        // watermark dibakar permanen ke dalamnya oleh WatermarkCompositor),
        // BUKAN `localFilePath` (versi ber-watermark yang jadi bukti final
        // tersimpan/tersinkron). Sebelumnya layar ini memakai
        // `localFilePath`, yang berarti panel navigasi hasil bake sudah
        // ikut tampil di foto latar - lalu GeotagPhotoLocationCard di
        // bawah dirender LAGI di atasnya sebagai overlay terpisah,
        // menghasilkan dua panel navigasi bertumpuk yang tidak sinkron
        // posisi/ukurannya (BoxFit.contain vs Positioned relatif layar) -
        // dilaporkan pengguna sebagai "navigasi lama menumpuk di balik
        // navigasi baru". Foto mentah tidak punya panel apa pun, jadi
        // hanya SATU panel (GeotagPhotoLocationCard) yang tampak di layar
        // ini. File ber-watermark (`localFilePath`) TETAP menjadi bukti
        // resmi yang disimpan/disinkronkan - tidak berubah sama sekali.
        Image.file(
          File(photo.originalFilePath ?? photo.localFilePath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),

        // 2. Header Status Bukti
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // Soft Success Green - sebelumnya aksen biru muda
                // (0xFF38BDF8) yang salah kaprah menyiratkan status
                // "informasi", padahal ini status SUKSES. Memakai token
                // AppColors.success yang sudah ada di design system
                // (bukan hex baru yang di-hardcode terpisah), diberi
                // opacity agar tetap legible di atas foto apa pun.
                color: AppColors.success.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bukti berhasil direkam • GPS ±${photo.gpsAccuracyMeters.round()} m',
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

        // 3. Floating Geotag Location Info Card (Sesuai Referensi 01.jpeg) + Action Buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xF20B132B), Colors.transparent],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kartu Lokasi Geotag Navigasi Lapangan (01.jpeg)
                  GeotagPhotoLocationCard(
                    latitude: photo.latitude,
                    longitude: photo.longitude,
                    accuracyMeters: photo.gpsAccuracyMeters,
                    address: photo.address,
                    timestamp: photo.serverTimestamp,
                    tag: 'NAVIGASI LAPANGAN',
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
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
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: controller.retakePhoto,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('Gunakan Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006EE6),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(photo),
                        ),
                      ),
                    ],
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
  // VIDEO REVIEW SCREEN
  // ====================================================================
  Widget _buildVideoReviewScreen(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    final videoPath = state.recordedVideoPath;
    final durationStr = state.formattedRecordingDuration;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0x33006EE6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF006EE6), width: 2),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Color(0xFF38BDF8),
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Video Dokumentasi Tersimpan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Durasi: $durationStr\nLokasi file: ${videoPath?.split(Platform.pathSeparator).last ?? ""}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Lokasi Geotag Navigasi Lapangan (01.jpeg)
              if (state.latitude != null && state.longitude != null)
                GeotagPhotoLocationCard(
                  latitude: state.latitude!,
                  longitude: state.longitude!,
                  accuracyMeters: state.accuracyMeters ?? 15.0,
                  address: state.address,
                  timestamp: state.currentTime,
                  tag: 'NAVIGASI LAPANGAN',
                ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Rekam Ulang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: controller.retakeVideo,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Gunakan Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006EE6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final success =
                            await controller.saveRecordedVideoEvidence(
                              caption: widget.taskName,
                            );
                        if (context.mounted && success) {
                          Navigator.of(context).pop(
                            controller.state.lastCapturedPhoto ?? videoPath,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // HELPER METHODS (BACK PRESS CONFIRMATION & OVERRIDE DIALOG)
  // ====================================================================
  void _handleBackPress(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    if (state.isRecordingVideo) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text(
            'Hentikan Perekaman?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Video sedang direkam. Apakah Anda ingin menghentikan perekaman dan keluar dari kamera?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await controller.stopVideoRecording(widget.cameraController);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Hentikan & Keluar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
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

  void _showLocationDetailsModal(
    BuildContext context,
    GeotagCameraController controller,
    GeotagCameraViewState state,
  ) {
    final lat = state.latitude != null ? state.latitude!.toStringAsFixed(6) : '--';
    final lng = state.longitude != null ? state.longitude!.toStringAsFixed(6) : '--';
    final acc = state.accuracyMeters != null ? '±${state.accuracyMeters!.round()} m' : 'Mencari sinyal...';
    final isGpsValid = state.locationStatus == LocationIntegrityStatus.valid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0x33006EE6), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGpsValid
                        ? const Color(0x3322C55E)
                        : const Color(0x33EF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isGpsValid
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Lokasi & Satelit GPS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGpsValid ? 'GPS Terkunci • Akurasi $acc' : 'Menunggu Sinyal GPS',
                        style: TextStyle(
                          color: isGpsValid ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),

            // Koordinat
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LATITUDE',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lat,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LONGITUDE',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lng,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Alamat Lengkap
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ALAMAT TERDETEKSI',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.address ?? 'Memuat alamat geocoding...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006EE6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

