import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  Login(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);
    result.fold(
      (_) {},
      (user) {
        _sessionManager?.updateUser(user);
      },
    );
    return result;
  }
}
