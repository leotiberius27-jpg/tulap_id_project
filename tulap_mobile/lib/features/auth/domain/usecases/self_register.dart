import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class SelfRegister {
  final AuthRepository _repository;

  SelfRegister(this._repository);

  Future<Either<Failure, AuthUserEntity>> call({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) {
    return _repository.selfRegister(
      fullName: fullName,
      email: email,
      password: password,
      instansiName: instansiName,
      phoneNumber: phoneNumber,
    );
  }
}
