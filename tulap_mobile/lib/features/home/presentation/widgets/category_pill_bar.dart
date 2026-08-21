import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/home_category.dart';

/// CategoryPillBar
/// ----------------------------------------------------------------------
/// Baris pill filter kategori horizontal di bawah hero header, mengikuti
/// pola navigasi aplikasi referensi. Kategorinya diturunkan dari nama
/// tugas yang sudah ada (lihat `home_category.dart`) - murni alat bantu
/// penyaringan visual, bukan field baru dari server.
/// ----------------------------------------------------------------------
class CategoryPillBar extends StatelessWidget {
  final HomeCategory selected;
  final ValueChanged<HomeCategory> onChanged;

  const CategoryPillBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: HomeCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = HomeCategory.values[index];
          final isSelected = category == selected;
          return _Pill(
            label: category.label,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              onChanged(category);
            },
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: AppMotion.stateChange,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? const []
              : const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
