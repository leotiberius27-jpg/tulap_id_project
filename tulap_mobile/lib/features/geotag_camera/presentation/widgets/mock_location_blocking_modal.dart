import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// MockLocationBlockingModal
/// ----------------------------------------------------------------------
/// Modal yang MEMBLOKIR proses capture saat mock location/perangkat
/// tidak memenuhi syarat terdeteksi (Bagian 21 & 28 spesifikasi -
/// microinteraction "Mock location: Red blocking modal").
///
/// Modal ini tidak bisa di-dismiss dengan tap di luar area (barrierDismissible:
/// false) - user harus benar-benar menonaktifkan lokasi palsu dulu
/// sebelum melanjutkan, karena ini menyangkut integritas bukti audit.
/// ----------------------------------------------------------------------
class MockLocationBlockingModal extends StatelessWidget {
  const MockLocationBlockingModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MockLocationBlockingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      icon: const Icon(Icons.gpp_bad, color: AppColors.danger, size: 48),
      title: const Text(
        'Lokasi Tidak Valid',
        textAlign: TextAlign.center,
        style: AppTypography.sectionTitle,
      ),
      content: const Text(
        'Lokasi perangkat tidak valid. Nonaktifkan lokasi palsu (fake GPS) '
        'pada perangkat Anda untuk melanjutkan pengambilan bukti.',
        textAlign: TextAlign.center,
        style: AppTypography.bodySecondary,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Saya Mengerti'),
        ),
      ],
    );
  }
}
