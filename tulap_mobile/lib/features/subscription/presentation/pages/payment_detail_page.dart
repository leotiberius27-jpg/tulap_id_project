import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/plan_config.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/payment_transaction_status.dart';
import '../../domain/usecases/get_payment_detail.dart';

/// PaymentDetailPage (Bagian 34 instruksi payment) - TIDAK PERNAH
/// menampilkan server key/webhook secret/raw token/provider payload.
/// ----------------------------------------------------------------------
class PaymentDetailPage extends StatefulWidget {
  final String publicReference;
  const PaymentDetailPage({super.key, required this.publicReference});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final GetPaymentDetail _getPaymentDetail = sl();
  PaymentTransactionEntity? _tx;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _getPaymentDetail(widget.publicReference);
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (tx) => setState(() {
        _tx = tx;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const AppLoadingView(label: 'Memuat detail pembayaran...')
            : _error != null
                ? AppErrorState(message: _error!, onRetry: _load)
                : _DetailBody(tx: _tx!),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PaymentTransactionEntity tx;
  const _DetailBody({required this.tx});

  String get _planDisplayName => switch (tx.planCode.name) {
    'basic' => 'Basic',
    'pro' => 'Tulap Pro',
    'proPlus' => 'Tulap Pro+',
    _ => 'Gratis',
  };

  String get _statusLabel => switch (tx.status) {
    PaymentTransactionStatus.paid => 'Berhasil',
    PaymentTransactionStatus.failed => 'Gagal',
    PaymentTransactionStatus.expired => 'Kedaluwarsa',
    PaymentTransactionStatus.cancelled => 'Dibatalkan',
    PaymentTransactionStatus.refunded => 'Dikembalikan',
    _ => 'Menunggu Pembayaran',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    final rows = <(String, String)>[
      ('Status', _statusLabel),
      ('Paket', _planDisplayName),
      ('Billing cycle', tx.billingCycle.label),
      ('Jumlah kegiatan', '${PlanConfig.byCode(tx.planCode).activityLimit} / bulan'),
      ('Total', AppDateFormatter.formatRupiah(tx.amount)),
      ('Metode pembayaran', tx.paymentMethod.name == 'qris' ? 'QRIS' : 'Virtual Account'),
      ('Nomor transaksi', tx.publicReference),
      ('Tanggal dibuat', AppDateFormatter.formatFullDateTime(tx.createdAt)),
      if (tx.paidAt != null) ('Tanggal pembayaran', AppDateFormatter.formatFullDateTime(tx.paidAt!)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows) ...[
              _DetailRow(label: row.$1, value: row.$2, colors: colors),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TulapThemeColors colors;
  const _DetailRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
