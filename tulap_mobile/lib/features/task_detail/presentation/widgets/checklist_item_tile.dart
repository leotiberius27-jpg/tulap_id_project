import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

/// ChecklistItemTile
/// ----------------------------------------------------------------------
/// Selaras dengan contoh checklist Bagian 7 spesifikasi:
///   ✓ Datang ke lokasi
///   ✓ Foto kondisi awal
///   ○ Foto kegiatan
/// Item wajib yang belum lengkap ditandai visual berbeda (border warna
/// warning) agar mudah dikenali sekilas dari daftar panjang.
/// ----------------------------------------------------------------------
class ChecklistItemTile extends StatelessWidget {
  final ChecklistItemEntity item;
  final ValueChanged<bool> onToggle;

  const ChecklistItemTile({super.key, required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final needsAttention = item.isMandatory && !item.isCompleted;

    return InkWell(
      onTap: () => onToggle(!item.isCompleted),
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: needsAttention
              ? Border.all(color: AppColors.warning.withOpacity(0.4))
              : null,
          color: needsAttention ? AppColors.warningSoft : null,
        ),
        child: Row(
          children: [
            Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? AppColors.success : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  color: item.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
            if (item.isMandatory && !item.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Wajib',
                  style: AppTypography.small.copyWith(color: AppColors.warning, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
