import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithApple {
  final AuthRepository _repository;

  LoginWithApple(this._repository);

  Future<Either<Failure, AuthUserEntity>> call({
    required String identityToken,
    String? fullName,
  }) {
    return _repository.loginWithApple(
      identityToken: identityToken,
      fullName: fullName,
    );
  }
}
