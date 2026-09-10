import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/payment_method_type.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/payment_transaction_status.dart';
import '../../domain/entities/plan_code.dart';

/// PaymentTransactionModel
/// ----------------------------------------------------------------------
/// Parsing response `PaymentsService.toSafeTransactionView()` di backend
/// (lihat tulap_backend/src/modules/payments/payments.service.ts).
/// ----------------------------------------------------------------------
class PaymentTransactionModel extends PaymentTransactionEntity {
  const PaymentTransactionModel({
    required super.publicReference,
    required super.planCode,
    required super.billingCycle,
    required super.amount,
    required super.currency,
    required super.paymentMethod,
    required super.status,
    super.qrString,
    super.vaBank,
    super.vaNumber,
    required super.createdAt,
    super.expiresAt,
    super.paidAt,
    super.failedAt,
    super.cancelledAt,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    final qris = json['qris'] as Map<String, dynamic>?;
    final va = json['virtualAccount'] as Map<String, dynamic>?;

    return PaymentTransactionModel(
      publicReference: json['publicReference'] as String,
      planCode: PlanCode.fromApiValue(json['planCode'] as String),
      billingCycle: BillingCycle.fromApiValue(json['billingCycle'] as String),
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'IDR',
      paymentMethod: PaymentMethodType.fromApiValue(json['paymentMethod'] as String),
      status: PaymentTransactionStatus.fromApiValue(json['status'] as String),
      qrString: qris?['qrString'] as String?,
      vaBank: va?['bank'] as String?,
      vaNumber: va?['vaNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      failedAt: json['failedAt'] != null ? DateTime.parse(json['failedAt'] as String) : null,
      cancelledAt:
          json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
    );
  }
}
