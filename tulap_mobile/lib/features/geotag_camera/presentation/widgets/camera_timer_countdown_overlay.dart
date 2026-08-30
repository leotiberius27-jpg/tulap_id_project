import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CameraTimerCountdownOverlay
/// ----------------------------------------------------------------------
/// Overlay hitung mundur rana kamera (Timer Shutter):
/// - Menampilkan angka besar animasi (3, 2, 1) di tengah preview
/// - Memungkinkan pembatalan instan hanya dengan mengetuk layar
/// - Memberikan haptic feedback saat angka berkurang
/// ----------------------------------------------------------------------
class CameraTimerCountdownOverlay extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onCancel;

  const CameraTimerCountdownOverlay({
    super.key,
    required this.remainingSeconds,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds <= 0) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        onCancel();
      },
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cincin & Angka Hitung Mundur Berdenyut
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey<int>(remainingSeconds),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC0A1120),
                    border: Border.all(
                      color: const Color(0xFF006EE6),
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66006EE6),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$remainingSeconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Batal Transparan
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Ketuk di mana saja untuk membatalkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
