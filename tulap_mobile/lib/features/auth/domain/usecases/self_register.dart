import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class SelfRegister {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  SelfRegister(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) async {
    final result = await _repository.selfRegister(
      fullName: fullName,
      email: email,
      password: password,
      instansiName: instansiName,
      phoneNumber: phoneNumber,
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
