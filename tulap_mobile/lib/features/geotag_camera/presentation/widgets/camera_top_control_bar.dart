import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../domain/usecases/validate_location_integrity.dart';
import 'gps_status_indicator.dart';

/// CameraTopControlBar
/// ----------------------------------------------------------------------
/// Baris perkakas kamera atas profesional Tulap.id (Phase 4):
/// [ ◉ Control Panel ]  [ ⚡ Flash ]  [ ✎ Rename ]  [ 📍 GPS Badge ]  [ 🔄 Switch ]  [ ⚙ Settings ]
///
/// Fitur:
/// - Ukuran target sentuh mematuhi standar aksesibilitas (>= 44x44dp)
/// - Indikator flash dinamis (Off, Auto, On, Torch)
/// - Tombol switch camera dengan animasi rotasi 200ms
/// - Tombol rename & kontrol panel terintegrasi
/// - Badge GPS live dengan status akurasi numerik
/// ----------------------------------------------------------------------
class CameraTopControlBar extends StatelessWidget {
  final bool isControlPanelOpen;
  final FlashMode flashMode;
  final bool isFlashSupported;
  final bool isSwitchingCamera;
  final bool isRecording;
  final LocationIntegrityStatus locationStatus;
  final LocationTier locationTier;
  final double? accuracyMeters;
  final VoidCallback? onToggleControlPanel;
  final VoidCallback onCycleFlash;
  final VoidCallback? onRename;
  final VoidCallback onSwitchCamera;
  final VoidCallback? onOpenSettings;
  final bool? isGridEnabled;
  final VoidCallback? onToggleGrid;
  final VoidCallback? onLocationTap;
  final VoidCallback? onBack;

  const CameraTopControlBar({
    super.key,
    this.isControlPanelOpen = false,
    required this.flashMode,
    required this.isFlashSupported,
    required this.isSwitchingCamera,
    this.isRecording = false,
    required this.locationStatus,
    required this.locationTier,
    required this.accuracyMeters,
    this.onToggleControlPanel,
    required this.onCycleFlash,
    this.onRename,
    required this.onSwitchCamera,
    this.onOpenSettings,
    this.isGridEnabled,
    this.onToggleGrid,
    this.onLocationTap,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null)
              _buildIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Kembali',
                onTap: onBack,
              )
            else
              // 1. Tombol Camera Control Panel (Lensa / Pengaturan Cepat)
              _buildIconButton(
                icon: Icons.tune_rounded,
                semanticLabel: 'Buka atau tutup panel kontrol kamera',
                isActive: isControlPanelOpen,
                isDisabled: isRecording,
                onTap: onToggleControlPanel,
              ),

            // 2. Tombol Flash Mode
            _buildFlashButton(context),

            if (onToggleGrid != null)
              _buildIconButton(
                icon: Icons.grid_on_rounded,
                semanticLabel: 'Toggle grid',
                isActive: isGridEnabled ?? false,
                onTap: onToggleGrid,
              )
            else
              // 3. Tombol Rename Pola Berkas (Pencil)
              _buildIconButton(
                icon: Icons.edit_note_rounded,
                semanticLabel: 'Atur pola nama berkas',
                isDisabled: isRecording,
                onTap: onRename,
              ),

            // 4. Badge Status GPS Real-time & Akurasi (Interactive Tap)
            GestureDetector(
              onTap: onLocationTap,
              child: GpsStatusIndicator(
                status: locationStatus,
                tier: locationTier,
                accuracyMeters: accuracyMeters,
              ),
            ),

            // 5. Tombol Switch / Putar Kamera (Depan / Belakang)
            _buildSwitchCameraButton(),

            // 6. Tombol Pengaturan Kamera Penuh (Gear)
            _buildIconButton(
              icon: Icons.settings_rounded,
              semanticLabel: 'Buka pengaturan kamera lengkap',
              isDisabled: isRecording,
              onTap: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashButton(BuildContext context) {
    IconData iconData;
    Color iconColor = Colors.white;
    String label = 'Flash Mati';
    bool isActive = false;

    if (!isFlashSupported) {
      iconData = Icons.flash_off_rounded;
      iconColor = Colors.white38;
      label = 'Flash Tidak Tersedia';
    } else {
      switch (flashMode) {
        case FlashMode.off:
          iconData = Icons.flash_off_rounded;
          iconColor = Colors.white;
          label = 'Flash Mati';
          break;
        case FlashMode.auto:
          iconData = Icons.flash_auto_rounded;
          iconColor = const Color(0xFF38BDF8); // Sky Blue
          label = 'Flash Otomatis';
          isActive = true;
          break;
        case FlashMode.always:
          iconData = Icons.flash_on_rounded;
          iconColor = const Color(0xFF006EE6); // Tulap Blue
          label = 'Flash Selalu Aktif';
          isActive = true;
          break;
        case FlashMode.torch:
          iconData = Icons.highlight_rounded;
          iconColor = const Color(0xFF006EE6); // Tulap Blue
          label = 'Lampu Senter Aktif';
          isActive = true;
          break;
      }
    }

    return _buildIconButton(
      icon: iconData,
      color: iconColor,
      semanticLabel: label,
      isActive: isActive,
      onTap: isFlashSupported
          ? onCycleFlash
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lampu flash tidak didukung pada sensor ini.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );
  }

  Widget _buildSwitchCameraButton() {
    return Semantics(
      button: true,
      label: 'Ganti kamera depan atau belakang',
      enabled: !isSwitchingCamera && !isRecording,
      child: GestureDetector(
        onTap: (isSwitchingCamera || isRecording)
            ? null
            : () {
                HapticFeedback.lightImpact();
                onSwitchCamera();
              },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.45),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Center(
            child: AnimatedRotation(
              turns: isSwitchingCamera ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.flip_camera_ios_rounded,
                color: isRecording ? Colors.white24 : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String semanticLabel,
    VoidCallback? onTap,
    Color color = Colors.white,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return Semantics(
      button: true,
      enabled: !isDisabled && onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: (isDisabled || onTap == null)
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.04)
                : (isActive
                    ? const Color(0x33006EE6)
                    : Colors.black.withValues(alpha: 0.45)),
            border: Border.all(
              color: isDisabled
                  ? Colors.white10
                  : (isActive
                      ? const Color(0xFF006EE6)
                      : Colors.white.withValues(alpha: 0.15)),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isDisabled
                  ? Colors.white24
                  : (isActive ? const Color(0xFF38BDF8) : color),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
