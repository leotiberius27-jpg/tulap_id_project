import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CameraCaptureMode
/// ----------------------------------------------------------------------
/// Mode perekaman kamera Tulap.id (sesuai referensi UI 01.jpeg):
/// - bagikanFoto: Mode ambil foto langsung siap bagikan
/// - photo: Mode FOTO standar geotag & watermark
/// - video: Mode perekaman VIDEO dokumentasi
/// - laporan: Mode LAPORAN formal institusi
/// ----------------------------------------------------------------------
enum CameraCaptureMode {
  bagikanFoto,
  photo,
  video,
  laporan,
}

/// CameraModeSelector
/// ----------------------------------------------------------------------
/// Bilah pemilih mode kamera horizontal di atas kontrol shutter (Referensi 01.jpeg):
///   BAGIKAN FOTO   [ FOTO ]   VIDEO   LAPORAN
///
/// Fitur:
/// - Mode aktif berlatar pill kuning keemasan (#FFC700) dengan teks tebal hitam
/// - Mode non-aktif berteks putih tebal dengan drop shadow kontras tinggi
/// - Haptic tactile feedback saat berganti mode
/// - Transisi halus dan responsif
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeItem(
              mode: CameraCaptureMode.bagikanFoto,
              label: 'BAGIKAN FOTO',
            ),
            const SizedBox(width: 14),
            _buildModeItem(
              mode: CameraCaptureMode.photo,
              label: 'FOTO',
            ),
            const SizedBox(width: 14),
            _buildModeItem(
              mode: CameraCaptureMode.video,
              label: 'VIDEO',
            ),
            const SizedBox(width: 14),
            _buildModeItem(
              mode: CameraCaptureMode.laporan,
              label: 'LAPORAN',
            ),
          ],
        ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 8,
            vertical: isSelected ? 5 : 5,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC700) : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.6,
              shadows: isSelected
                  ? null
                  : const [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

