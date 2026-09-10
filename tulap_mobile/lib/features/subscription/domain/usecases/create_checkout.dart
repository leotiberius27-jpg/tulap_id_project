import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/billing_cycle.dart';
import '../entities/payment_method_type.dart';
import '../entities/payment_transaction_entity.dart';
import '../entities/plan_code.dart';
import '../repositories/payment_repository.dart';

class CreateCheckout {
  final PaymentRepository _repository;
  CreateCheckout(this._repository);

  Future<Either<Failure, PaymentTransactionEntity>> call({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  }) {
    return _repository.checkout(
      planCode: planCode,
      billingCycle: billingCycle,
      paymentMethod: paymentMethod,
      checkoutAttemptId: checkoutAttemptId,
      vaBank: vaBank,
    );
  }
}
