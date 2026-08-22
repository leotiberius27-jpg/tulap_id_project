import '../repositories/auth_repository.dart';

class DisableBiometricLogin {
  final AuthRepository _repository;

  DisableBiometricLogin(this._repository);

  Future<void> call() => _repository.disableBiometricLogin();
}
