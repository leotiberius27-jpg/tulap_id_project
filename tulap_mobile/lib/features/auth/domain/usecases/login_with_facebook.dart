import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithFacebook {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  LoginWithFacebook(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String accessToken,
    String? email,
    String? fullName,
  }) async {
    final result = await _repository.loginWithFacebook(
      accessToken: accessToken,
      email: email,
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
