import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/tula_visibility_controller.dart';

/// TulaContextSummary
/// ----------------------------------------------------------------------
/// Merangkum kelengkapan bukti Detail Tugas yang sedang dibuka memakai
/// data NYATA dari TaskDetailController (checklist, foto, nota, catatan)
/// - lihat TulaTaskContextBinder. Tula menunjukkan kekurangan & CTA,
/// bukan mengeksekusi perubahan kritis sendiri (user tetap menekan CTA).
/// ----------------------------------------------------------------------
class TulaContextSummary extends StatelessWidget {
  final TulaTaskSummary summary;
  final VoidCallback onPrimaryAction;

  const TulaContextSummary({
    super.key,
    required this.summary,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    final rows = <_InsightRow>[
      _InsightRow(
        ok: summary.hasLocationValid,
        okText: 'Lokasi sudah valid',
        badText: 'Lokasi perangkat tidak valid',
      ),
      _InsightRow(
        ok: summary.evidenceCount > 0,
        okText: '${summary.evidenceCount} foto sudah tersimpan',
        badText: 'Foto bukti belum ada',
      ),
      if (summary.checklistTotal > 0)
        _InsightRow(
          ok: summary.checklistRemaining == 0,
          okText: 'Semua checklist selesai',
          badText: '${summary.checklistRemaining} checklist belum selesai',
        ),
      _InsightRow(
        ok: summary.hasReceipt,
        okText: 'Nota sudah dilampirkan',
        badText: 'Nota BBM/kegiatan belum dilampirkan',
      ),
    ];

    final String ctaLabel;
    if (summary.checklistRemaining > 0) {
      ctaLabel = 'Lengkapi Checklist';
    } else if (!summary.hasReceipt) {
      ctaLabel = 'Scan Nota';
    } else {
      ctaLabel = 'Tinjau & Kirim Tugas';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary.taskTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.ok ? '✓' : '⚠',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: r.ok ? colors.success : colors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.ok ? r.okText : r.badText,
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(ctaLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow {
  final bool ok;
  final String okText;
  final String badText;

  const _InsightRow({required this.ok, required this.okText, required this.badText});
}
