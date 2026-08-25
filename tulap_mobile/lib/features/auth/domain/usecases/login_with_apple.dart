import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithApple {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  LoginWithApple(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String identityToken,
    String? fullName,
  }) async {
    final result = await _repository.loginWithApple(
      identityToken: identityToken,
      fullName: fullName,
    );
    result.fold(
      (_) {},
      (user) {
        _sessionManager?.updateUser(user);
      },
    );
    return result;
  }
}
