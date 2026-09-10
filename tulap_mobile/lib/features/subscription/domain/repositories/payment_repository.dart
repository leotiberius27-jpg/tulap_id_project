import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/billing_cycle.dart';
import '../entities/payment_method_type.dart';
import '../entities/payment_transaction_entity.dart';
import '../entities/plan_code.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaymentTransactionEntity>> checkout({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  });

  Future<Either<Failure, List<PaymentTransactionEntity>>> getHistory();

  Future<Either<Failure, PaymentTransactionEntity>> getDetail(String publicReference);

  Future<Either<Failure, PaymentTransactionEntity>> checkStatus(String publicReference);
}
