import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'task_photo_gallery_sheet.dart';

/// CameraBottomBar
/// ----------------------------------------------------------------------
/// Baris kontrol kamera profesional di bagian bawah layar:
///   [Gallery Preview]      [Shutter Capture]      [Flip Camera]
///
/// Fitur:
/// - Shutter button responsif dengan animasi sentuh (Haptic + Scale)
/// - Menampilkan preview thumbnail foto tugas terakhir & jumlah foto
/// - Tombol switch/flip kamera depan & belakang
/// - Validasi shutter dengan fallback modal jika GPS belum terkunci
/// ----------------------------------------------------------------------
class CameraBottomBar extends StatelessWidget {
  final GeotagCameraViewState state;
  final VoidCallback onCapture;
  final VoidCallback onFlipCamera;
  final VoidCallback onLowAccuracyTap;
  final List<GeotagPhotoEntity> taskPhotos;

  const CameraBottomBar({
    super.key,
    required this.state,
    required this.onCapture,
    required this.onFlipCamera,
    required this.onLowAccuracyTap,
    required this.taskPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tombol Galeri / Preview Foto Tugas
            _buildGalleryButton(context),

            // 2. Tombol Shutter Utama
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

    return Semantics(
      button: true,
      label: 'Galeri foto tugas',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          TaskPhotoGallerySheet.show(context, photos: taskPhotos);
        },
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
                    errorBuilder: (_, __, ___) => const Center(
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
    );
  }

  Widget _buildShutterButton() {
    final isCapturing = state.captureStatus == CaptureViewStatus.capturing;
    final canCapture = state.isCaptureEnabled;

    return Semantics(
      button: true,
      label: 'Ambil foto bukti',
      enabled: !isCapturing,
      child: GestureDetector(
        onTap: isCapturing
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
    return Semantics(
      button: true,
      label: 'Putar kamera',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onFlipCamera();
        },
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
    );
  }
}
