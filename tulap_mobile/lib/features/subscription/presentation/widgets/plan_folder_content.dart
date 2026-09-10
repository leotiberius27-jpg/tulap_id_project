import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_usage_entity.dart';
import 'plan_usage_card.dart';

/// PlanFolderContent
/// ----------------------------------------------------------------------
/// Isi inner content sheet satu folder (Bagian 23 dokumen redesign):
/// jumlah kegiatan (informasi paling prominent setelah nama paket),
/// harga, deskripsi singkat, daftar benefit, lalu CTA/usage sesuai
/// status kepemilikan paket ini oleh user. Motion HANYA pada container
/// folder (lihat PlanFolderCarousel) - teks di sini stabil (Bagian 42).
/// ----------------------------------------------------------------------
class PlanFolderContent extends StatelessWidget {
  final PlanEntity plan;
  final BillingCycle billingCycle;
  final bool isCurrentPlan;
  final SubscriptionUsageEntity? usage;
  final String ctaLabel;
  final bool isCtaEnabled;
  final bool isCtaLoading;
  final VoidCallback? onCtaPressed;

  const PlanFolderContent({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.isCurrentPlan,
    required this.usage,
    required this.ctaLabel,
    required this.isCtaEnabled,
    required this.isCtaLoading,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final price = plan.priceFor(billingCycle);

    // Header+benefit dibungkus Expanded+SingleChildScrollView (bukan Column
    // tetap) supaya TIDAK PERNAH overflow - mis. teks "Hemat Rp.../tahun"
    // pada mode Tahunan yang menambah satu baris, atau font scale besar
    // (Bagian 43-44 dokumen redesign). CTA dipin di luar area scroll,
    // selalu terlihat.
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isCurrentPlan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.successSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'PAKET ANDA SAAT INI',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: colors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Text(
                      '${plan.activityLimit}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'kegiatan / bulan',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: plan.isFree
                                ? 'Gratis'
                                : AppDateFormatter.formatRupiah(price),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                          if (!plan.isFree)
                            TextSpan(
                              text: billingCycle.priceSuffix,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!plan.isFree && billingCycle == BillingCycle.annual) ...[
                    const SizedBox(height: 3),
                    Center(
                      child: Text(
                        'setara ${AppDateFormatter.formatRupiah(plan.annualEquivalentMonthly)}/bulan'
                        '${plan.annualSavingAmount > 0 ? ' · Hemat ${AppDateFormatter.formatRupiah(plan.annualSavingAmount)}/tahun' : ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    plan.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isCurrentPlan && usage != null)
                    PlanUsageCard(usage: usage!)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: plan.benefits
                          .map((benefit) => _BenefitRow(label: benefit))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isCtaEnabled && !isCtaLoading ? onCtaPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan
                    ? colors.successSoft
                    : colors.action,
                foregroundColor: isCurrentPlan ? colors.success : Colors.white,
                disabledBackgroundColor: colors.border,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: isCtaLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      ctaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String label;

  const _BenefitRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
