import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/payment_transaction_status.dart';
import '../controllers/payment_history_controller.dart';
import 'payment_detail_page.dart';

/// PaymentHistoryPage ("Riwayat Pembayaran" - Bagian 33 instruksi payment)
/// ----------------------------------------------------------------------
class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentHistoryController>(
      create: (_) => PaymentHistoryController(getPaymentHistory: sl())..load(),
      child: const _PaymentHistoryView(),
    );
  }
}

class _PaymentHistoryView extends StatelessWidget {
  const _PaymentHistoryView();

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final controller = context.watch<PaymentHistoryController>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: switch (controller.status) {
          PaymentHistoryStatus.loading => const AppLoadingView(
              label: 'Memuat riwayat pembayaran...',
            ),
          PaymentHistoryStatus.error => AppErrorState(
              message: controller.errorMessage ?? 'Terjadi kesalahan.',
              onRetry: controller.load,
            ),
          PaymentHistoryStatus.loaded => controller.items.isEmpty
              ? const AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada riwayat pembayaran',
                  message: 'Transaksi QRIS/VA Anda akan muncul di sini.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) => _HistoryTile(tx: controller.items[index]),
                ),
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PaymentTransactionEntity tx;
  const _HistoryTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final statusInfo = _statusInfo(tx.status, colors);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentDetailPage(publicReference: tx.publicReference),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateFormatter.formatCompact(tx.createdAt),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _planDisplayName(tx),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppDateFormatter.formatRupiah(tx.amount)} • ${tx.paymentMethod.name == 'qris' ? 'QRIS' : 'Virtual Account'}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusInfo.$2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusInfo.$1,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusInfo.$3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _planDisplayName(PaymentTransactionEntity tx) => switch (tx.planCode.name) {
    'basic' => 'Basic',
    'pro' => 'Tulap Pro',
    'proPlus' => 'Tulap Pro+',
    _ => 'Gratis',
  };

  (String, Color, Color) _statusInfo(PaymentTransactionStatus status, TulapThemeColors colors) {
    return switch (status) {
      PaymentTransactionStatus.paid => ('Berhasil', colors.successSoft, colors.success),
      PaymentTransactionStatus.failed => ('Gagal', colors.dangerSoft, colors.danger),
      PaymentTransactionStatus.expired => ('Kedaluwarsa', colors.warningSoft, colors.warning),
      PaymentTransactionStatus.cancelled => ('Dibatalkan', colors.warningSoft, colors.warning),
      PaymentTransactionStatus.refunded => ('Dikembalikan', colors.warningSoft, colors.warning),
      _ => ('Menunggu', colors.warningSoft, colors.warning),
    };
  }
}
