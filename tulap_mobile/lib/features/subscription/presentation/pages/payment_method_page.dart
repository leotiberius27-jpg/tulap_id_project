import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/payment_method_type.dart';
import '../../domain/entities/plan_entity.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/tula_suppressed_scope.dart';
import 'payment_status_page.dart';

/// PaymentMethodPage ("Pilih Metode Pembayaran")
/// ----------------------------------------------------------------------
/// Bagian 7 instruksi payment. Menekan QRIS membuat transaksi langsung;
/// menekan Virtual Account membuka pemilihan bank terlebih dulu (backend
/// butuh kode bank VA - Bagian 14), baru transaksi dibuat.
/// ----------------------------------------------------------------------
class PaymentMethodPage extends StatelessWidget {
  final PlanEntity plan;
  final BillingCycle billingCycle;

  const PaymentMethodPage({
    super.key,
    required this.plan,
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    return TulaSuppressedScope(
      child: ChangeNotifierProvider<CheckoutController>(
        create: (_) => CheckoutController(
          createCheckout: sl(),
          plan: plan,
          billingCycle: billingCycle,
        ),
        child: const _PaymentMethodView(),
      ),
    );
  }
}

class _PaymentMethodView extends StatelessWidget {
  const _PaymentMethodView();

  Future<void> _submit(
    BuildContext context,
    CheckoutController controller,
    PaymentMethodType method, {
    String? vaBank,
  }) async {
    HapticFeedback.selectionClick();
    final success = await controller.submit(method, vaBank: vaBank);
    if (!context.mounted) return;

    if (success && controller.transaction != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PaymentStatusPage(transaction: controller.transaction!),
        ),
      );
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickVaBank(
    BuildContext context,
    CheckoutController controller,
  ) async {
    final colors = context.tulapColors;
    final bank = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.base),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Bank Virtual Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...vaSupportedBanks.map(
                (bank) => ListTile(
                  title: Text(
                    bank.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(bank),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (bank != null && context.mounted) {
      await _submit(
        context,
        controller,
        PaymentMethodType.virtualAccount,
        vaBank: bank,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final controller = context.watch<CheckoutController>();
    final isSubmitting = controller.status == CheckoutStatus.submitting;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Pilih Metode Pembayaran'),
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
              _PaymentMethodCard(
                title: 'QRIS',
                subtitle:
                    'Bayar dengan aplikasi bank atau e-wallet yang mendukung QRIS',
                icon: Icons.qr_code_2_rounded,
                enabled: !isSubmitting,
                onTap: () =>
                    _submit(context, controller, PaymentMethodType.qris),
              ),
              const SizedBox(height: AppSpacing.md),
              _PaymentMethodCard(
                title: 'Transfer Virtual Account',
                subtitle: 'Transfer melalui channel bank yang tersedia',
                icon: Icons.account_balance_outlined,
                enabled: !isSubmitting,
                onTap: () => _pickVaBank(context, controller),
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
              if (isSubmitting) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: CircularProgressIndicator(color: colors.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.iconSoftBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.action),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
