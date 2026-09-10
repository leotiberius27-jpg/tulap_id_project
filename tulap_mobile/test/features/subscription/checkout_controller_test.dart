import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/billing_cycle.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_method_type.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_transaction_entity.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_transaction_status.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/plan_code.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/plan_entity.dart';
import 'package:tulap_mobile/features/subscription/domain/repositories/payment_repository.dart';
import 'package:tulap_mobile/features/subscription/domain/usecases/create_checkout.dart';
import 'package:tulap_mobile/features/subscription/presentation/controllers/checkout_controller.dart';

/// Fake PaymentRepository - merekam parameter yang dikirim controller
/// (khususnya checkoutAttemptId) tanpa memanggil backend sungguhan.
class _FakePaymentRepository implements PaymentRepository {
  final List<String> checkoutAttemptIds = [];
  bool shouldFail = false;

  PaymentTransactionEntity _makeTx(PaymentMethodType method) => PaymentTransactionEntity(
    publicReference: 'TLPTEST1',
    planCode: PlanCode.pro,
    billingCycle: BillingCycle.monthly,
    amount: 39000,
    currency: 'IDR',
    paymentMethod: method,
    status: PaymentTransactionStatus.pending,
    createdAt: DateTime(2026, 9, 8),
  );

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkout({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  }) async {
    checkoutAttemptIds.add(checkoutAttemptId);
    if (shouldFail) {
      return const Left(ServerFailure('Gagal membuat transaksi pembayaran.'));
    }
    return Right(_makeTx(paymentMethod));
  }

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkStatus(String publicReference) async =>
      Right(_makeTx(PaymentMethodType.qris));

  @override
  Future<Either<Failure, PaymentTransactionEntity>> getDetail(String publicReference) async =>
      Right(_makeTx(PaymentMethodType.qris));

  @override
  Future<Either<Failure, List<PaymentTransactionEntity>>> getHistory() async => const Right([]);
}

void main() {
  final plan = const PlanEntity(
    code: PlanCode.pro,
    displayName: 'Tulap Pro',
    tabLabel: 'PRO',
    description: 'desc',
    activityLimit: 30,
    monthlyPrice: 39000,
    annualPrice: 390000,
    benefits: [],
    ctaLabel: 'Pilih Tulap Pro',
  );

  late _FakePaymentRepository repository;
  late CheckoutController controller;

  setUp(() {
    repository = _FakePaymentRepository();
    controller = CheckoutController(
      createCheckout: CreateCheckout(repository),
      plan: plan,
      billingCycle: BillingCycle.monthly,
    );
  });

  test('displayedAmount murni informasi - harga otoritatif tetap dihitung server', () {
    expect(controller.displayedAmount, 39000);
  });

  test('submit sukses menyimpan transaksi dan status success', () async {
    final success = await controller.submit(PaymentMethodType.qris);

    expect(success, true);
    expect(controller.status, CheckoutStatus.success);
    expect(controller.transaction?.publicReference, 'TLPTEST1');
  });

  test('submit gagal menyimpan pesan error dan status error', () async {
    repository.shouldFail = true;
    final success = await controller.submit(PaymentMethodType.qris);

    expect(success, false);
    expect(controller.status, CheckoutStatus.error);
    expect(controller.errorMessage, isNotNull);
  });

  test(
    'Bagian 32 instruksi payment: retry pada metode yang SAMA memakai ulang checkoutAttemptId '
    '(mencegah double payment)',
    () async {
      await controller.submit(PaymentMethodType.qris);
      await controller.submit(PaymentMethodType.qris);

      expect(repository.checkoutAttemptIds.length, 2);
      expect(repository.checkoutAttemptIds[0], repository.checkoutAttemptIds[1]);
    },
  );

  test('beralih ke metode LAIN (QRIS -> VA) memakai checkoutAttemptId yang berbeda', () async {
    await controller.submit(PaymentMethodType.qris);
    await controller.submit(PaymentMethodType.virtualAccount, vaBank: 'bca');

    expect(repository.checkoutAttemptIds.length, 2);
    expect(repository.checkoutAttemptIds[0], isNot(repository.checkoutAttemptIds[1]));
  });
}
