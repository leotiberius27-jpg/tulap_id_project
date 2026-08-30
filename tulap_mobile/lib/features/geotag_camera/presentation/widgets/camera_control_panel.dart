import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/camera_preferences_entity.dart';
import '../controllers/geotag_camera_controller.dart';
import 'camera_add_text_sheet.dart';

/// CameraControlPanel
/// ----------------------------------------------------------------------
/// Expandable Camera Control Panel (Phase 4):
/// - Membuka panel transparan gelap (88-94% opacity) di atas preview kamera
/// - Kamera tetap LIVE dan terlihat di balik panel
/// - Grid kontrol 4-baris responsif:
///     Baris 1: Rasio, Grid, Timer
///     Baris 2: Panduan Fokus, Mirror Depan, Suara Shutter
///     Baris 3: White Balance, Level Horizon, Tambahkan Teks
///     Baris 4: Audio Video
/// - Tombol & ubin menggunakan aksen Tulap.id Blue (#006EE6 & #38BDF8)
/// ----------------------------------------------------------------------
class CameraControlPanel extends StatelessWidget {
  final GeotagCameraController controller;
  final CameraController? cameraController;
  final CameraLensDirection currentLensDirection;
  final VoidCallback onClose;

  const CameraControlPanel({
    super.key,
    required this.controller,
    required this.cameraController,
    required this.currentLensDirection,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final prefs = state.cameraPreferences;
    final isFrontCamera = currentLensDirection == CameraLensDirection.front;
    final isRecording = state.isRecordingVideo;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEB0A1120), // Dark Navy ~92% Opacity
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(
          color: const Color(0x3338BDF8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Panel: Judul & Tombol Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0x26006EE6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF38BDF8),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'KONTROL KAMERA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onClose();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // GRID BARIS 1: Rasio | Grid | Timer
              Row(
                children: [
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.aspect_ratio_rounded,
                      label: 'Rasio',
                      value: prefs.aspectRatio.label,
                      isActive: prefs.aspectRatio != CameraAspectRatio.ratio4x3,
                      isDisabled: isRecording,
                      onTap: () => controller.cycleAspectRatio(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: prefs.gridEnabled
                          ? Icons.grid_on_rounded
                          : Icons.grid_off_rounded,
                      label: 'Grid',
                      value: prefs.gridEnabled ? '3x3' : 'Mati',
                      isActive: prefs.gridEnabled,
                      onTap: () => controller.toggleGrid(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.timer_outlined,
                      label: 'Timer',
                      value: prefs.timerSeconds > 0
                          ? '${prefs.timerSeconds}s'
                          : 'Mati',
                      isActive: prefs.timerSeconds > 0,
                      isDisabled: isRecording,
                      onTap: () => controller.cycleTimer(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // GRID BARIS 2: Panduan Fokus | Mirror Depan | Suara Shutter
              Row(
                children: [
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.center_focus_strong_rounded,
                      label: 'Fokus',
                      value: prefs.focusGuideEnabled ? 'Aktif' : 'Mati',
                      isActive: prefs.focusGuideEnabled,
                      onTap: () => controller.toggleFocusGuide(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.flip_camera_android_rounded,
                      label: 'Mirror',
                      value: !isFrontCamera
                          ? 'Belakang'
                          : (prefs.mirrorFrontCamera ? 'Aktif' : 'Mati'),
                      isActive: isFrontCamera && prefs.mirrorFrontCamera,
                      isDisabled: !isFrontCamera || isRecording,
                      onTap: () => controller.toggleMirrorFrontCamera(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: prefs.shutterSoundPreference ==
                              ShutterSoundPreference.disabled
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      label: 'Suara',
                      value: prefs.shutterSoundPreference.label,
                      isActive: prefs.shutterSoundPreference ==
                          ShutterSoundPreference.enabled,
                      onTap: () => controller.cycleShutterSound(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // GRID BARIS 3: White Balance | Level Horizon | Tambah Teks
              Row(
                children: [
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.wb_sunny_outlined,
                      label: 'W. Balance',
                      value: prefs.whiteBalance.label,
                      isActive:
                          prefs.whiteBalance != CameraWhiteBalanceMode.auto,
                      isDisabled: isRecording ||
                          !controller.capabilities.supportsWhiteBalance,
                      onTap: () => controller.cycleWhiteBalance(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.screen_rotation_alt_rounded,
                      label: 'Level',
                      value: prefs.levelEnabled ? 'Aktif' : 'Mati',
                      isActive: prefs.levelEnabled,
                      onTap: () => controller.toggleLevelSensor(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlTile(
                      icon: Icons.edit_note_rounded,
                      label: 'Teks',
                      value: state.caption != null && state.caption!.isNotEmpty
                          ? 'Ada Catatan'
                          : 'Tambah',
                      isActive:
                          state.caption != null && state.caption!.isNotEmpty,
                      onTap: () {
                        onClose();
                        CameraAddTextSheet.show(
                          context,
                          currentCaption: state.caption,
                          onSave: (note) => controller.setCustomCaption(note),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // GRID BARIS 4: Audio Video
              _VideoAudioTile(
                isEnabled: prefs.videoAudioEnabled,
                isDisabled: isRecording,
                onToggle: () => controller.toggleVideoAudio(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Control Tile Individual
class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isActive = false,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBlue = const Color(0xFF006EE6);
    final skyBlue = const Color(0xFF38BDF8);

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: '$label: $value',
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.03)
                : (isActive
                    ? activeBlue.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.07)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled
                  ? Colors.white10
                  : (isActive ? skyBlue : Colors.white12),
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDisabled
                    ? Colors.white24
                    : (isActive ? skyBlue : Colors.white),
                size: 20,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.white24 : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDisabled
                      ? Colors.white24
                      : (isActive ? skyBlue : Colors.white),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile Baris Penuh Audio Video
class _VideoAudioTile extends StatelessWidget {
  final bool isEnabled;
  final bool isDisabled;
  final VoidCallback onToggle;

  const _VideoAudioTile({
    required this.isEnabled,
    this.isDisabled = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final skyBlue = const Color(0xFF38BDF8);

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: 'Rekam video dengan suara: ${isEnabled ? "Aktif" : "Nonaktif"}',
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                onToggle();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0x29006EE6)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled ? skyBlue : Colors.white12,
              width: isEnabled ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                color: isEnabled ? skyBlue : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rekam Video dengan Suara',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isEnabled
                          ? 'Mikrofon aktif selama perekaman video'
                          : 'Video akan direkam tanpa suara (hening)',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? const Color(0xFF006EE6)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEnabled ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
