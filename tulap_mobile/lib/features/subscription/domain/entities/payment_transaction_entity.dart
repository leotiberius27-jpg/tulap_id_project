import 'billing_cycle.dart';
import 'payment_method_type.dart';
import 'payment_transaction_status.dart';
import 'plan_code.dart';

/// PaymentTransactionEntity
/// ----------------------------------------------------------------------
/// Bentuk aman satu transaksi QRIS/VA sebagaimana dikembalikan backend
/// (PaymentsService.toSafeTransactionView - tidak pernah membawa secret
/// atau raw provider payload). `publicReference` adalah identitas yang
/// ditampilkan ke user, BUKAN id database (Bagian 10 instruksi payment).
/// ----------------------------------------------------------------------
class PaymentTransactionEntity {
  final String publicReference;
  final PlanCode planCode;
  final BillingCycle billingCycle;
  final int amount;
  final String currency;
  final PaymentMethodType paymentMethod;
  final PaymentTransactionStatus status;

  /// QRIS - null jika paymentMethod bukan QRIS atau provider belum
  /// mengembalikan payload.
  final String? qrString;

  /// Virtual Account - null jika paymentMethod bukan VA.
  final String? vaBank;
  final String? vaNumber;

  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;

  const PaymentTransactionEntity({
    required this.publicReference,
    required this.planCode,
    required this.billingCycle,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.qrString,
    this.vaBank,
    this.vaNumber,
    required this.createdAt,
    this.expiresAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
  });

  bool get isExpiredByClock =>
      expiresAt != null && status.isWaitingPayment && DateTime.now().isAfter(expiresAt!);
}
