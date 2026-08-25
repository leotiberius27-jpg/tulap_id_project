import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogle {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  LoginWithGoogle(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    final result = await _repository.loginWithGoogle(
      idToken: idToken,
      email: email,
      displayName: displayName,
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
