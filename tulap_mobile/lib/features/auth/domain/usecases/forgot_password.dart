import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPassword {
  final AuthRepository _repository;

  ForgotPassword(this._repository);

  Future<Either<Failure, String>> call(String email) {
    return _repository.forgotPassword(email);
  }
}
