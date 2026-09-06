import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// TulaOfflineState
/// ----------------------------------------------------------------------
/// Ditampilkan di dalam Tula Bottom Sheet saat perangkat offline.
/// Tulap.id adalah aplikasi offline-first - salinan ini sengaja
/// menghindari istilah teknis ("Network Error", "AI request failed")
/// dan menegaskan bahwa pekerjaan/bukti user tetap aman tersimpan.
/// ----------------------------------------------------------------------
class TulaOfflineState extends StatelessWidget {
  final VoidCallback onLihatTugas;
  final VoidCallback onLihatDataTersimpan;

  const TulaOfflineState({
    super.key,
    required this.onLihatTugas,
    required this.onLihatDataTersimpan,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Anda sedang offline.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fitur bantuan Tula yang membutuhkan internet akan tersedia '
            'kembali setelah perangkat terhubung.',
            style: TextStyle(fontSize: 13, height: 1.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Pekerjaan dan bukti Anda tetap tersimpan di perangkat.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onLihatTugas,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lihat Tugas'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onLihatDataTersimpan,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lihat Data Tersimpan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
