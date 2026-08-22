import '../repositories/auth_repository.dart';

class EnableBiometricLogin {
  final AuthRepository _repository;

  EnableBiometricLogin(this._repository);

  Future<void> call() => _repository.enableBiometricLogin();
}
