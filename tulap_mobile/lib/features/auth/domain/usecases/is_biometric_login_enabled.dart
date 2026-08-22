import '../repositories/auth_repository.dart';

class IsBiometricLoginEnabled {
  final AuthRepository _repository;

  IsBiometricLoginEnabled(this._repository);

  Future<bool> call() => _repository.isBiometricLoginEnabled();
}
