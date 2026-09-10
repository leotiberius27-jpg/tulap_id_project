import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_transaction_entity.dart';
import '../repositories/payment_repository.dart';

class GetPaymentDetail {
  final PaymentRepository _repository;
  GetPaymentDetail(this._repository);

  Future<Either<Failure, PaymentTransactionEntity>> call(String publicReference) {
    return _repository.getDetail(publicReference);
  }
}
