import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/plan_entity.dart';
import '../widgets/tula_suppressed_scope.dart';
import 'payment_method_page.dart';

/// PurchaseSummaryPage ("Ringkasan Pembayaran")
/// ----------------------------------------------------------------------
/// Langkah pertama alur checkout setelah user menekan CTA paket di Plan
/// Folder Carousel (Bagian 7 & 39 instruksi payment). Halaman paket TIDAK
/// diubah sama sekali - hanya CTA-nya dihubungkan ke sini lewat
/// SubscriptionPage._handleCtaPressed.
/// ----------------------------------------------------------------------
class PurchaseSummaryPage extends StatelessWidget {
  final PlanEntity plan;
  final BillingCycle billingCycle;

  const PurchaseSummaryPage({
    super.key,
    required this.plan,
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final price = plan.priceFor(billingCycle);

    return TulaSuppressedScope(
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Ringkasan Pembayaran'),
          centerTitle: true,
          backgroundColor: colors.surface,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(
                          AppRadius.cardLarge,
                        ),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayName,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan.activityLimit} kegiatan / bulan',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13.5,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _SummaryRow(
                            label: 'Periode',
                            value: billingCycle.label,
                            colors: colors,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Divider(color: colors.border, height: 1),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13.5,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppDateFormatter.formatRupiah(price),
                            semanticsLabel:
                                '${AppDateFormatter.formatRupiah(price)} ${billingCycle.priceSuffix}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Pembayaran diverifikasi otomatis. Paket aktif setelah pembayaran berhasil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentMethodPage(
                            plan: plan,
                            billingCycle: billingCycle,
                          ),
                        ),
                      );
                    },
                    child: const Text('Lanjutkan Pembayaran'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TulapThemeColors colors;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.5,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
