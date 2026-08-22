import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogle {
  final AuthRepository _repository;

  LoginWithGoogle(this._repository);

  Future<Either<Failure, AuthUserEntity>> call(String idToken) {
    return _repository.loginWithGoogle(idToken);
  }
}
