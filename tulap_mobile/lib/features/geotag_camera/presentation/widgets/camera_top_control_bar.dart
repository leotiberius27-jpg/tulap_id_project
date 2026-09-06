import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../domain/usecases/validate_location_integrity.dart';

/// CameraTopControlBar
/// ----------------------------------------------------------------------
/// Baris perkakas kamera atas profesional Tulap.id (Referensi 01.jpeg):
/// [ ⚙️/Ratio ]  [ ⚡ Flash ]  [ 📝+ Catatan ]  [ 📍 Lokasi ]  [ ⏱️ Timer ]  [ ⚙️ Settings ]
///
/// Fitur:
/// - 6 ikon perkakas atas presisi sesuai gambar referensi 01.jpeg
/// - Ikon putih outline elegan dengan kontras tinggi di atas gradient
/// - Indikator flash dinamis (Mati, Otomatis, Nyala, Senter)
/// - Indikator timer aktif dengan badge detik (3s, 5s, 10s)
/// - Indikator lokasi interaktif dengan status GPS real-time
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
  final int timerSeconds;
  final VoidCallback? onToggleControlPanel;
  final VoidCallback onCycleFlash;
  final VoidCallback? onRename;
  final VoidCallback? onAddText;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onCycleTimer;
  final VoidCallback? onLocationTap;
  final bool? isGridEnabled;
  final VoidCallback? onToggleGrid;
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
    this.timerSeconds = 0,
    this.onToggleControlPanel,
    required this.onCycleFlash,
    this.onRename,
    this.onAddText,
    this.onSwitchCamera,
    this.onOpenSettings,
    this.onCycleTimer,
    this.onLocationTap,
    this.isGridEnabled,
    this.onToggleGrid,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              // 1. Ikon 1: Aperture / Rasio / Quick Panel (Lingkaran Bersegmen dari 01.jpeg)
              _buildIconButton(
                icon: Icons.motion_photos_on_outlined,
                semanticLabel: 'Panel Kontrol & Rasio Kamera',
                isActive: isControlPanelOpen,
                isDisabled: isRecording,
                onTap: onToggleControlPanel,
              ),

            // 2. Ikon 2: Flash Mode (Lightning bolt with slash / auto / on)
            _buildFlashButton(context),

            if (onToggleGrid != null)
              _buildIconButton(
                icon: Icons.grid_on_rounded,
                semanticLabel: 'Toggle grid',
                isActive: isGridEnabled ?? false,
                onTap: onToggleGrid,
              )
            else
              // 3. Ikon 3: Note / Keterangan Teks / Stamp Data (Page with +)
              _buildIconButton(
                icon: Icons.note_add_outlined,
                semanticLabel: 'Tambah Keterangan atau Pola Nama',
                isDisabled: isRecording,
                onTap: onAddText ?? onRename,
              ),

            // 4. Ikon 4: Lokasi / Map Pin (Square with pin dari 01.jpeg)
            _buildLocationButton(),

            // 5. Ikon 5: Timer Shutter Speed (Circle with clock/dial dari 01.jpeg)
            _buildTimerButton(),

            // 6. Ikon 6: Settings Gear (Pengaturan Lengkap)
            _buildIconButton(
              icon: Icons.settings_outlined,
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
          iconColor = const Color(0xFFFFC700); // Yellow highlight
          label = 'Flash Otomatis';
          isActive = true;
          break;
        case FlashMode.always:
          iconData = Icons.flash_on_rounded;
          iconColor = const Color(0xFFFFC700); // Yellow highlight
          label = 'Flash Selalu Aktif';
          isActive = true;
          break;
        case FlashMode.torch:
          iconData = Icons.highlight_rounded;
          iconColor = const Color(0xFFFFC700);
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

  Widget _buildLocationButton() {
    final isGpsValid = locationStatus == LocationIntegrityStatus.valid;
    final gpsColor = isGpsValid
        ? (accuracyMeters != null && accuracyMeters! <= 15.0
            ? const Color(0xFF22C55E)
            : const Color(0xFFFFC700))
        : const Color(0xFFEF4444);

    return Semantics(
      button: true,
      label: 'Status Lokasi GPS',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onLocationTap?.call();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: isGpsValid
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0x66EF4444),
              width: 1,
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: gpsColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
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

  Widget _buildTimerButton() {
    final isTimerActive = timerSeconds > 0;

    return Semantics(
      button: true,
      label: isTimerActive ? 'Timer $timerSeconds detik' : 'Timer Mati',
      child: GestureDetector(
        onTap: isRecording
            ? null
            : () {
                HapticFeedback.selectionClick();
                onCycleTimer?.call();
              },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTimerActive
                ? const Color(0x33FFC700)
                : Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: isTimerActive
                  ? const Color(0xFFFFC700)
                  : Colors.white.withValues(alpha: 0.2),
              width: isTimerActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: isTimerActive
                ? Text(
                    '${timerSeconds}s',
                    style: const TextStyle(
                      color: Color(0xFFFFC700),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 22,
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
                    ? const Color(0x33FFC700)
                    : Colors.black.withValues(alpha: 0.35)),
            border: Border.all(
              color: isDisabled
                  ? Colors.white10
                  : (isActive
                      ? const Color(0xFFFFC700)
                      : Colors.white.withValues(alpha: 0.2)),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isDisabled
                  ? Colors.white24
                  : (isActive ? const Color(0xFFFFC700) : color),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

