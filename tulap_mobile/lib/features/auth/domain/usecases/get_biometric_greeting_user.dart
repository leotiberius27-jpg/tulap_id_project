import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

class GetBiometricGreetingUser {
  final AuthRepository _repository;

  GetBiometricGreetingUser(this._repository);

  Future<AuthUserEntity?> call() => _repository.getBiometricGreetingUser();
}
