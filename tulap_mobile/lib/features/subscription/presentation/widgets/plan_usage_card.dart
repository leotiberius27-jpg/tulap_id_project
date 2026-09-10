import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/subscription_usage_entity.dart';

/// PlanUsageCard
/// ----------------------------------------------------------------------
/// Menampilkan pemakaian kuota kegiatan paket yang sedang aktif dipakai
/// user (Bagian 27-29 dokumen redesign). Tidak pernah menakut-nakuti -
/// warning HANYA muncul saat benar-benar mendekati/mencapai limit, dan
/// selalu memakai tanggal reset SUNGGUHAN (`usage.periodEnd`), bukan
/// nilai rekaan.
/// ----------------------------------------------------------------------
class PlanUsageCard extends StatelessWidget {
  final SubscriptionUsageEntity usage;

  const PlanUsageCard({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final tone = usage.isAtLimit
        ? AppStatusTone.warning
        : (usage.isNearLimit ? AppStatusTone.warning : AppStatusTone.success);
    final barColor = StatusColor.foreground(context, tone);
    final resetLabel = AppDateFormatter.formatFull(usage.periodEnd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${usage.used} / ${usage.limit} kegiatan digunakan',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: usage.progress,
            minHeight: 8,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          usage.isAtLimit
              ? 'Kuota kegiatan bulan ini telah digunakan.'
              : 'Sisa ${usage.remaining} kegiatan',
          semanticsLabel: usage.isAtLimit
              ? 'Kuota kegiatan bulan ini telah digunakan'
              : 'Sisa ${usage.remaining} kegiatan bulan ini',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Diperbarui $resetLabel',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
