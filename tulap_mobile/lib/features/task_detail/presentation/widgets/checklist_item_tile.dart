import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

/// ChecklistItemTile
/// ----------------------------------------------------------------------
/// Selaras dengan contoh checklist Bagian 7 spesifikasi:
///   ✓ Datang ke lokasi
///   ✓ Foto kondisi awal
///   ○ Foto kegiatan
/// Sesuai Bagian 21 spesifikasi visual: checklist TIDAK boleh terlihat
/// seperti form pemerintah - baris bersih tanpa kotak/border per-item,
/// hanya ikon status + chip kecil ("Wajib"/"Opsional") yang membedakan
/// prioritas. Pemisah antar baris memakai Divider tipis (dirender oleh
/// parent), bukan kotak bertumpuk.
/// ----------------------------------------------------------------------
class ChecklistItemTile extends StatelessWidget {
  final ChecklistItemEntity item;
  final ValueChanged<bool> onToggle;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle(!item.isCompleted);
      },
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.stateChange,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                item.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                key: ValueKey(item.isCompleted),
                color: item.isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.stateChange,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                child: Text(item.label),
              ),
            ),
            if (!item.isCompleted) ...[
              const SizedBox(width: AppSpacing.sm),
              _PriorityChip(isMandatory: item.isMandatory),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final bool isMandatory;

  const _PriorityChip({required this.isMandatory});

  @override
  Widget build(BuildContext context) {
    final color = isMandatory ? AppColors.warning : AppColors.textSecondary;
    final background = isMandatory
        ? AppColors.warningSoft
        : AppColors.background;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMandatory ? 'Wajib' : 'Opsional',
        style: AppTypography.small.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
