import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CameraCaptureMode
/// ----------------------------------------------------------------------
/// Mode perekaman kamera Tulap.id:
/// - photo: Pengambilan foto tunggal dengan metadata geotag & watermark
/// - video: Perekaman video dokumentasi dinas dengan audio & live timer
/// ----------------------------------------------------------------------
enum CameraCaptureMode { photo, video }

/// CameraModeSelector
/// ----------------------------------------------------------------------
/// Bilah pemilih mode kamera di atas kontrol shutter:
///   [ FOTO ]      [ VIDEO ]
///
/// Fitur:
/// - Mode aktif ditandai dengan teks Tulap.id Blue (#006EE6) & titik indikator
/// - Transisi animasi halus saat perpindahan mode
/// - Non-aktif otomatis saat video sedang direkam (anti-race-condition)
/// ----------------------------------------------------------------------
class CameraModeSelector extends StatelessWidget {
  final CameraCaptureMode selectedMode;
  final bool isRecording;
  final ValueChanged<CameraCaptureMode> onModeChanged;

  const CameraModeSelector({
    super.key,
    required this.selectedMode,
    required this.isRecording,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeItem(
            mode: CameraCaptureMode.photo,
            label: 'FOTO',
          ),
          const SizedBox(width: 24),
          _buildModeItem(
            mode: CameraCaptureMode.video,
            label: 'VIDEO',
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required CameraCaptureMode mode,
    required String label,
  }) {
    final isSelected = selectedMode == mode;

    return Semantics(
      button: true,
      label: 'Mode $label',
      selected: isSelected,
      enabled: !isRecording,
      child: GestureDetector(
        onTap: isRecording
            ? null
            : () {
                if (selectedMode != mode) {
                  HapticFeedback.selectionClick();
                  onModeChanged(mode);
                }
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isRecording ? 0.35 : (isSelected ? 1.0 : 0.65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF006EE6) // Tulap.id Blue
                      : Colors.white,
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.8,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF006EE6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
