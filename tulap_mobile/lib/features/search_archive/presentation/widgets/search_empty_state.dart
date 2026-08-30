import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchEmptyState extends StatelessWidget {
  final String query;
  final bool hasFilters;
  final VoidCallback onResetFilters;

  const SearchEmptyState({
    super.key,
    required this.query,
    required this.hasFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isSearching = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.infoSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.folder_open_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Tidak ditemukan hasil untuk "$query"'
                  : 'Belum Ada Arsip Data',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Periksa kembali kata kunci pencarian atau sesuaikan filter untuk menemukan arsip yang sesuai.'
                  : 'Seluruh kegiatan, dokumentasi foto, nota pengeluaran, dan paket LPJ akan tersimpan rapi dan dapat dicari di sini kapan saja.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Semua Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
