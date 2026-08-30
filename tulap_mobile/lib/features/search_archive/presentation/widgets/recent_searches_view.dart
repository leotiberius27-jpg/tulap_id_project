import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recent_search_entity.dart';

class RecentSearchesView extends StatelessWidget {
  final List<RecentSearchEntity> recentSearches;
  final ValueChanged<String> onSearchTapped;
  final ValueChanged<String> onRemoveTapped;
  final VoidCallback onClearAllTapped;

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    required this.onSearchTapped,
    required this.onRemoveTapped,
    required this.onClearAllTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Pencarian Terakhir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearAllTapped,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(fontSize: 11, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: recentSearches.map((item) {
              return InputChip(
                label: Text(item.query),
                onPressed: () => onSearchTapped(item.query),
                onDeleted: () => onRemoveTapped(item.id),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconColor: AppColors.textMuted,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
