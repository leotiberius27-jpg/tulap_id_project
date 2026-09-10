import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// PlanPageIndicator
/// ----------------------------------------------------------------------
/// Dot indicator carousel (Bagian 25 dokumen redesign). Selected state
/// TIDAK hanya mengandalkan warna - dot terpilih juga melebar, dan
/// semantics diekspos untuk screen reader.
/// ----------------------------------------------------------------------
class PlanPageIndicator extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const PlanPageIndicator({
    super.key,
    required this.count,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Semantics(
      label: 'Paket ${selectedIndex + 1} dari $count dipilih',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isSelected = index == selectedIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isSelected ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}
