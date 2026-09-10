import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_transaction_entity.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistory {
  final PaymentRepository _repository;
  GetPaymentHistory(this._repository);

  Future<Either<Failure, List<PaymentTransactionEntity>>> call() {
    return _repository.getHistory();
  }
}
