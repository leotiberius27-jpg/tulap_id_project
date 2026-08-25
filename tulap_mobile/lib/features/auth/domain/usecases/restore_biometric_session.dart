import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class RestoreBiometricSession {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  RestoreBiometricSession(this._repository, [this._sessionManager]);

  Future<AuthUserEntity?> call() async {
    final user = await _repository.restoreBiometricSession();
    if (user != null) {
      _sessionManager?.updateUser(user);
    }
    return user;
  }
}
