import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/tula_visibility_controller.dart';

/// Daftar quick action kontekstual maksimum 3-4 per layar (Bagian 11
/// spesifikasi redesign Tula) - dipetakan dari layar yang sedang aktif
/// supaya Tula tidak terasa seperti chatbot generik.
List<String> tulaQuickActionsFor(TulaScreenContext screen) {
  switch (screen) {
    case TulaScreenContext.home:
      return const [
        'Apa tugas saya hari ini?',
        'Apa yang perlu saya selesaikan?',
        'Cek status sinkronisasi',
        'Bantuan Tulap',
      ];
    case TulaScreenContext.taskDetail:
      return const [
        'Cek kelengkapan bukti',
        'Apa checklist yang belum selesai?',
        'Scan nota',
        'Buka lokasi tugas',
      ];
    case TulaScreenContext.receiptReview:
      return const [
        'Cek nota',
        'Apa nominal yang terbaca?',
        'Apa data yang perlu diperiksa?',
      ];
    case TulaScreenContext.lpj:
      return const [
        'Cek kelengkapan LPJ',
        'Apa yang belum lengkap?',
        'Bantu siapkan LPJ',
      ];
    case TulaScreenContext.taskList:
    case TulaScreenContext.history:
    case TulaScreenContext.general:
      return const [
        'Apa tugas saya hari ini?',
        'Cek status sinkronisasi',
        'Bantuan Tulap',
      ];
  }
}

class TulaQuickActions extends StatelessWidget {
  final List<String> actions;
  final ValueChanged<String> onSelect;

  const TulaQuickActions({
    super.key,
    required this.actions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final colors = context.tulapColors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        return InkWell(
          onTap: () => onSelect(action),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              action,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
