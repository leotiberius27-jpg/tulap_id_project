import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// HistoryPage (Riwayat)
/// ----------------------------------------------------------------------
/// Tab "Riwayat" di bottom navigation. TIDAK ADA sumber data aktivitas
/// (usecase/endpoint) di domain layer saat ini - sengaja ditampilkan
/// sebagai empty state JUJUR, bukan data rekayasa/dummy, sesuai prinsip
/// "jangan sembunyikan realita dengan interface palsu". Diisi dengan
/// data asli begitu domain/backend menyediakan riwayat aktivitas.
/// ----------------------------------------------------------------------
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat')),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.history,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Riwayat belum tersedia',
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Catatan aktivitas Anda (foto, nota, sinkronisasi) '
                  'akan muncul di sini pada pembaruan berikutnya.',
                  style: AppTypography.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
