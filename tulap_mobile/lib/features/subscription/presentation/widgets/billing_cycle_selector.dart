import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/billing_cycle.dart';

/// BillingCycleSelector
/// ----------------------------------------------------------------------
/// Segmented control "Bulanan | Tahunan" (Bagian 1 & 26 dokumen
/// redesign). Mengganti siklus TIDAK PERNAH mereset carousel atau
/// paket terpilih - hanya memicu re-render harga di controller.
/// ----------------------------------------------------------------------
class BillingCycleSelector extends StatelessWidget {
  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  const BillingCycleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: BillingCycle.values.map((cycle) {
          final isSelected = cycle == value;
          return _SegmentTab(
            label: cycle.label,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              onChanged(cycle);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 96, minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
