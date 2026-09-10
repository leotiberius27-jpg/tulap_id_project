import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/billing_cycle.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_method_type.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_transaction_entity.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/payment_transaction_status.dart';
import 'package:tulap_mobile/features/subscription/domain/entities/plan_code.dart';
import 'package:tulap_mobile/features/subscription/domain/repositories/payment_repository.dart';
import 'package:tulap_mobile/features/subscription/domain/usecases/check_payment_status.dart';
import 'package:tulap_mobile/features/subscription/presentation/controllers/payment_status_controller.dart';

class _FakePaymentRepository implements PaymentRepository {
  int checkStatusCallCount = 0;
  bool shouldFail = false;
  PaymentTransactionStatus nextStatus = PaymentTransactionStatus.pending;

  PaymentTransactionEntity _tx(PaymentTransactionStatus status) => PaymentTransactionEntity(
    publicReference: 'TLPTEST1',
    planCode: PlanCode.pro,
    billingCycle: BillingCycle.monthly,
    amount: 39000,
    currency: 'IDR',
    paymentMethod: PaymentMethodType.qris,
    status: status,
    createdAt: DateTime(2026, 9, 8),
  );

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkStatus(String publicReference) async {
    checkStatusCallCount++;
    if (shouldFail) {
      return const Left(ServerFailure('Tidak dapat memeriksa pembayaran saat ini.'));
    }
    return Right(_tx(nextStatus));
  }

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkout({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  }) async => Right(_tx(PaymentTransactionStatus.pending));

  @override
  Future<Either<Failure, PaymentTransactionEntity>> getDetail(String publicReference) async =>
      Right(_tx(PaymentTransactionStatus.pending));

  @override
  Future<Either<Failure, List<PaymentTransactionEntity>>> getHistory() async => const Right([]);
}

void main() {
  late _FakePaymentRepository repository;

  PaymentTransactionEntity pendingTx() => PaymentTransactionEntity(
    publicReference: 'TLPTEST1',
    planCode: PlanCode.pro,
    billingCycle: BillingCycle.monthly,
    amount: 39000,
    currency: 'IDR',
    paymentMethod: PaymentMethodType.qris,
    status: PaymentTransactionStatus.pending,
    createdAt: DateTime(2026, 9, 8),
  );

  setUp(() {
    repository = _FakePaymentRepository();
  });

  test('refresh() manual (tombol Cek Status Pembayaran) memperbarui transaksi dari backend', () async {
    repository.nextStatus = PaymentTransactionStatus.paid;
    final controller = PaymentStatusController(
      checkPaymentStatus: CheckPaymentStatus(repository),
      transaction: pendingTx(),
    );
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.transaction.status, PaymentTransactionStatus.paid);
    expect(controller.lastCheckFailed, false);
  });

  test(
    'Bagian 29 instruksi payment: kegagalan jaringan TIDAK mengubah status transaksi, '
    'hanya menandai lastCheckFailed',
    () async {
      repository.shouldFail = true;
      final controller = PaymentStatusController(
        checkPaymentStatus: CheckPaymentStatus(repository),
        transaction: pendingTx(),
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.transaction.status, PaymentTransactionStatus.pending);
      expect(controller.lastCheckFailed, true);
    },
  );

  test('Bagian 13 instruksi payment: berhenti polling saat status sudah final (PAID)', () async {
    final paidTx = PaymentTransactionEntity(
      publicReference: 'TLPTEST1',
      planCode: PlanCode.pro,
      billingCycle: BillingCycle.monthly,
      amount: 39000,
      currency: 'IDR',
      paymentMethod: PaymentMethodType.qris,
      status: PaymentTransactionStatus.paid,
      createdAt: DateTime(2026, 9, 8),
    );
    final controller = PaymentStatusController(
      checkPaymentStatus: CheckPaymentStatus(repository),
      transaction: paidTx,
    );
    addTearDown(controller.dispose);

    // Status sudah PAID sejak awal -> tidak ada polling terjadwal,
    // checkStatus TIDAK PERNAH dipanggil otomatis.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(repository.checkStatusCallCount, 0);
  });
}
