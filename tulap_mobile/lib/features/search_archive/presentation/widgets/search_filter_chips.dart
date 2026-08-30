import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_result_entity.dart';

class SearchFilterChips extends StatelessWidget {
  final SearchEntityType? selectedType;
  final ValueChanged<SearchEntityType?> onSelected;

  const SearchFilterChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <_ChipOption>[
      const _ChipOption(label: 'Semua', type: null, icon: Icons.grid_view),
      const _ChipOption(label: 'Kegiatan', type: SearchEntityType.activity, icon: Icons.assignment_outlined),
      const _ChipOption(label: 'Perjalanan', type: SearchEntityType.travel, icon: Icons.flight_takeoff),
      const _ChipOption(label: 'Dokumentasi', type: SearchEntityType.evidence, icon: Icons.camera_alt_outlined),
      const _ChipOption(label: 'Nota', type: SearchEntityType.receipt, icon: Icons.receipt_long_outlined),
      const _ChipOption(label: 'Laporan', type: SearchEntityType.report, icon: Icons.description_outlined),
      const _ChipOption(label: 'Dokumen', type: SearchEntityType.document, icon: Icons.insert_drive_file_outlined),
      const _ChipOption(label: 'LPJ', type: SearchEntityType.lpj, icon: Icons.folder_special_outlined),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = selectedType == opt.type;

          return InkWell(
            onTap: () => onSelected(opt.type),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: AppColors.shadowSoft,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipOption {
  final String label;
  final SearchEntityType? type;
  final IconData icon;

  const _ChipOption({
    required this.label,
    required this.type,
    required this.icon,
  });
}
