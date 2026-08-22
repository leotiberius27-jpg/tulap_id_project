import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class RestoreBiometricSession {
  final AuthRepository _repository;

  RestoreBiometricSession(this._repository);

  Future<AuthUserEntity?> call() => _repository.restoreBiometricSession();
}
