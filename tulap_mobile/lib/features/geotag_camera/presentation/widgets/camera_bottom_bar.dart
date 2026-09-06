import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../evidence_gallery/presentation/pages/evidence_viewer_page.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'camera_mode_selector.dart';

/// CameraBottomBar
/// ----------------------------------------------------------------------
/// Baris kontrol kamera bawah profesional Tulap.id (Sesuai Referensi 01.jpeg):
///   [Pratinjau]   [Lokasi]   (( Shutter ))   [Default]   [Template]
///
/// Fitur:
/// - 5 tombol kontrol bawah presisi dengan ikon dan label teks di bawahnya
/// - Pratinjau: Thumbnail lingkaran foto terakhir dengan badge counter
/// - Lokasi: Ikon pin peta untuk membuka modal informasi koordinat
/// - Shutter: Tombol bulat putih solid dengan ring luar elegan
/// - Default: Ikon folder/preset untuk manajemen pola berkas dan teks
/// - Template: Ikon grid 4-kotak untuk membuka selector watermark
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
  final VoidCallback? onLocationTap;
  final VoidCallback? onPresetTap;
  final VoidCallback? onTemplateTap;
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
    this.onLocationTap,
    this.onPresetTap,
    this.onTemplateTap,
    this.taskId,
    this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Pratinjau (Gallery Preview)
            _buildBottomLabeledButton(
              label: 'Pratinjau',
              semanticLabel: 'Buka galeri pratinjau foto',
              iconWidget: _buildGalleryThumbnail(context),
              onTap: () {
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
            ),

            // 2. Lokasi (Map Pin)
            _buildBottomLabeledButton(
              label: 'Lokasi',
              semanticLabel: 'Buka detail lokasi GPS',
              iconWidget: const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 26,
              ),
              onTap: onLocationTap ?? onLowAccuracyTap,
            ),

            // 3. Tombol Shutter Utama (Center Large Capture Button)
            _buildShutterButton(),

            // 4. Default (Preset / Pola Berkas)
            _buildBottomLabeledButton(
              label: 'Default',
              semanticLabel: 'Pengaturan preset atau pola berkas',
              iconWidget: const Icon(
                Icons.folder_open_outlined,
                color: Colors.white,
                size: 26,
              ),
              onTap: onPresetTap ?? onFlipCamera,
            ),

            // 5. Template (Grid 4 Kotak Watermark Selector)
            _buildBottomLabeledButton(
              label: 'Template',
              semanticLabel: 'Pilih template watermark',
              iconWidget: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 26,
              ),
              onTap: onTemplateTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLabeledButton({
    required String label,
    required String semanticLabel,
    required Widget iconWidget,
    required VoidCallback? onTap,
  }) {
    final isRecording = state.isRecordingVideo;

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: !isRecording && onTap != null,
      child: GestureDetector(
        onTap: isRecording
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isRecording ? 0.35 : 1.0,
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 38,
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryThumbnail(BuildContext context) {
    final latestPhoto = taskPhotos.isNotEmpty ? taskPhotos.first : null;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.8,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (latestPhoto != null)
            ClipOval(
              child: Image.file(
                File(latestPhoto.localFilePath),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            )
          else
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 18,
            ),

          if (taskPhotos.isNotEmpty)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC700),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  '${taskPhotos.length}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShutterButton() {
    final isVideoMode = state.cameraMode == CameraCaptureMode.video;
    final isRecording = state.isRecordingVideo;
    final isCapturing = state.captureStatus == CaptureViewStatus.capturing;
    final canCapture = state.isCaptureEnabled;

    if (isVideoMode) {
      // VIDEO SHUTTER CONTROL
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
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3.5,
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
              width: isRecording ? 30 : 60,
              height: isRecording ? 30 : 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(isRecording ? 8 : 99),
              ),
            ),
          ),
        ),
      );
    }

    // PHOTO SHUTTER CONTROL (01.jpeg: Solid white button with outer white ring)
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
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: canCapture
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              width: 3.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCapturing
                  ? Colors.white24
                  : (canCapture
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35)),
            ),
            child: isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F172A),
                      strokeWidth: 3.5,
                    ),
                  )
                : (!canCapture
                      ? const Icon(
                          Icons.gps_fixed_rounded,
                          color: Colors.black54,
                          size: 24,
                        )
                      : null),
          ),
        ),
      ),
    );
  }
}

