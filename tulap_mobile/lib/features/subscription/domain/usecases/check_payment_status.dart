import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_transaction_entity.dart';
import '../repositories/payment_repository.dart';

/// CheckPaymentStatus
/// ----------------------------------------------------------------------
/// "Cek Status Pembayaran" (Bagian 13, 26, 31 instruksi payment) - selalu
/// lewat backend (yang lalu bertanya ke provider), TIDAK PERNAH memanggil
/// provider langsung dari mobile.
/// ----------------------------------------------------------------------
class CheckPaymentStatus {
  final PaymentRepository _repository;
  CheckPaymentStatus(this._repository);

  Future<Either<Failure, PaymentTransactionEntity>> call(String publicReference) {
    return _repository.checkStatus(publicReference);
  }
}
