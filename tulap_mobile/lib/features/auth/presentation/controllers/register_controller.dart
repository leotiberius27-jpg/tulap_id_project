import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/self_register.dart';

enum RegisterStatus { idle, submitting, error }

class RegisterState {
  final RegisterStatus status;
  final AuthUserEntity? user;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.idle,
    this.user,
    this.errorMessage,
  });
}

/// RegisterController
/// ----------------------------------------------------------------------
/// Registrasi mandiri (layar "Daftar") - SELALU membuat akun ber-role
/// PEGAWAI (lihat SelfRegister/AuthService.selfRegister backend), dan
/// langsung login otomatis jika berhasil, sama seperti alur Login biasa.
/// ----------------------------------------------------------------------
class RegisterController extends ChangeNotifier {
  final SelfRegister _selfRegister;

  RegisterState _state = const RegisterState();
  RegisterState get state => _state;

  RegisterController({required SelfRegister selfRegister})
      : _selfRegister = selfRegister;

  void _update(RegisterState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> submit({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) async {
    _update(const RegisterState(status: RegisterStatus.submitting));

    final result = await _selfRegister(
      fullName: fullName,
      email: email,
      password: password,
      instansiName: instansiName,
      phoneNumber: phoneNumber,
    );

    return result.fold(
      (failure) {
        _update(RegisterState(status: RegisterStatus.error, errorMessage: failure.message));
        return false;
      },
      (user) {
        _update(RegisterState(status: RegisterStatus.idle, user: user));
        return true;
      },
    );
  }
}
