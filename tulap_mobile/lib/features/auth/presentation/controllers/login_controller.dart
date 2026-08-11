import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/login.dart';

enum LoginStatus { idle, submitting, error }

class LoginState {
  final LoginStatus status;
  final AuthUserEntity? user;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.idle,
    this.user,
    this.errorMessage,
  });
}

/// LoginController
/// ----------------------------------------------------------------------
/// Mengorkestrasi submit form Login ke `Login` usecase. State `user`
/// pada hasil sukses langsung dipakai LoginPage untuk navigasi ke
/// Beranda tanpa perlu membaca ulang sesi dari penyimpanan lokal.
/// ----------------------------------------------------------------------
class LoginController extends ChangeNotifier {
  final Login _login;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  LoginController({required Login login}) : _login = login;

  void _update(LoginState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> submit({required String email, required String password}) async {
    _update(const LoginState(status: LoginStatus.submitting));

    final result = await _login(email: email, password: password);

    return result.fold(
      (failure) {
        _update(LoginState(status: LoginStatus.error, errorMessage: failure.message));
        return false;
      },
      (user) {
        _update(LoginState(status: LoginStatus.idle, user: user));
        return true;
      },
    );
  }
}
