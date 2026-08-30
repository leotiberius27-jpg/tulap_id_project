import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'camera_mode_selector.dart';
import 'task_photo_gallery_sheet.dart';

/// CameraBottomBar
/// ----------------------------------------------------------------------
/// Baris kontrol kamera profesional di bagian bawah layar:
///   [Gallery Preview]      [Shutter / Record]      [Flip Camera]
///
/// Fitur:
/// - Shutter button responsif dengan animasi sentuh (Haptic + Scale)
/// - Mode Foto: Shutter putih bersih dengan aksen Tulap.id Blue (#006EE6)
/// - Mode Video: Shutter merah lingkaran (mulai) & kotak merah (berhenti)
/// - Menampilkan preview thumbnail foto tugas terakhir & jumlah foto
/// - Tombol switch/flip kamera depan & belakang
/// - Validasi shutter dengan fallback modal jika GPS belum terkunci
/// ----------------------------------------------------------------------
class CameraBottomBar extends StatelessWidget {
  final GeotagCameraViewState state;
  final VoidCallback onCapture;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onFlipCamera;
  final VoidCallback onLowAccuracyTap;
  final List<GeotagPhotoEntity> taskPhotos;
  final VoidCallback? onOpenGallery;
  final String? taskId;
  final String? taskName;

  const CameraBottomBar({
    super.key,
    required this.state,
    required this.onCapture,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onFlipCamera,
    required this.onLowAccuracyTap,
    required this.taskPhotos,
    this.onOpenGallery,
    this.taskId,
    this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tombol Galeri / Preview Foto Tugas
            _buildGalleryButton(context),

            // 2. Tombol Shutter Utama (Foto / Video)
            _buildShutterButton(),

            // 3. Tombol Flip Kamera (Depan / Belakang)
            _buildFlipButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    final latestPhoto = taskPhotos.isNotEmpty ? taskPhotos.first : null;
    final isRecording = state.isRecordingVideo;

    return Semantics(
      button: true,
      label: 'Galeri foto tugas',
      enabled: !isRecording,
      child: GestureDetector(
        onTap: isRecording
            ? null
            : () {
                HapticFeedback.lightImpact();
                if (onOpenGallery != null) {
                  onOpenGallery!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EvidenceViewerPage(
                        initialEvidenceList: taskPhotos,
                        initialIndex: 0,
                        taskId: taskId ?? (taskPhotos.isNotEmpty ? taskPhotos.first.taskId : ''),
                        taskName: taskName,
                      ),
                    ),
                  );
                }
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isRecording ? 0.3 : 1.0,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (latestPhoto != null)
                  ClipOval(
                    child: Image.file(
                      File(latestPhoto.localFilePath),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                if (taskPhotos.isNotEmpty)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006EE6),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${taskPhotos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    final isVideoMode = state.cameraMode == CameraCaptureMode.video;
    final isRecording = state.isRecordingVideo;
    final isCapturing = state.captureStatus == CaptureViewStatus.capturing;
    final canCapture = state.isCaptureEnabled;

    if (isVideoMode) {
      // ----------------------------------------------------------------
      // VIDEO SHUTTER CONTROL (Start / Stop Recording)
      // ----------------------------------------------------------------
      return Semantics(
        button: true,
        label: isRecording ? 'Hentikan rekaman video' : 'Mulai rekam video',
        child: GestureDetector(
          onTap: () {
            if (isRecording) {
              HapticFeedback.lightImpact();
              onStopRecording();
            } else {
              HapticFeedback.heavyImpact();
              onStartRecording();
            }
          },
          child: Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4.5,
              ),
              boxShadow: isRecording
                  ? const [
                      BoxShadow(
                        color: Color(0x80EF4444),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isRecording ? 34 : 64,
              height: isRecording ? 34 : 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444), // Red recording
                borderRadius: BorderRadius.circular(isRecording ? 8 : 99),
              ),
            ),
          ),
        ),
      );
    }

    // ------------------------------------------------------------------
    // PHOTO SHUTTER CONTROL (Atomic Photo Capture)
    // ------------------------------------------------------------------
    return Semantics(
      button: true,
      label: 'Ambil foto bukti',
      enabled: !isCapturing && !state.isSwitchingCamera,
      child: GestureDetector(
        onTap: (isCapturing || state.isSwitchingCamera)
            ? null
            : (canCapture
                  ? () {
                      HapticFeedback.mediumImpact();
                      onCapture();
                    }
                  : () {
                      HapticFeedback.heavyImpact();
                      onLowAccuracyTap();
                    }),
        child: Container(
          width: 82,
          height: 82,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: canCapture
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              width: 4.5,
            ),
            boxShadow: canCapture
                ? const [
                    BoxShadow(
                      color: Color(0x66006EE6),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCapturing
                  ? Colors.white24
                  : (canCapture
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25)),
            ),
            child: isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      color: Color(0xFF006EE6),
                      strokeWidth: 3.5,
                    ),
                  )
                : (!canCapture
                      ? const Icon(
                          Icons.gps_fixed_rounded,
                          color: Colors.white70,
                          size: 26,
                        )
                      : null),
          ),
        ),
      ),
    );
  }

  Widget _buildFlipButton() {
    final isRecording = state.isRecordingVideo;

    return Semantics(
      button: true,
      label: 'Putar kamera',
      enabled: !isRecording && !state.isSwitchingCamera,
      child: GestureDetector(
        onTap: (isRecording || state.isSwitchingCamera)
            ? null
            : () {
                HapticFeedback.lightImpact();
                onFlipCamera();
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isRecording ? 0.3 : 1.0,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
