import 'package:flutter/foundation.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_google.dart';

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
  final LoginWithGoogle _loginWithGoogle;
  final LoginWithApple _loginWithApple;
  final OAuthSignInService _oauthSignInService;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  LoginController({
    required Login login,
    required LoginWithGoogle loginWithGoogle,
    required LoginWithApple loginWithApple,
    required OAuthSignInService oauthSignInService,
  })  : _login = login,
        _loginWithGoogle = loginWithGoogle,
        _loginWithApple = loginWithApple,
        _oauthSignInService = oauthSignInService;

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

  /// Masuk dengan Google - memicu SDK native Google Sign-In sungguhan
  /// (bukan simulasi), lalu idToken hasilnya diverifikasi backend.
  /// Mengembalikan `null` (bukan error) jika user membatalkan dialog
  /// pemilihan akun - itu bukan kegagalan, cukup diam.
  Future<bool?> submitWithGoogle() async {
    _update(const LoginState(status: LoginStatus.submitting));

    try {
      final idToken = await _oauthSignInService.signInWithGoogle();
      if (idToken == null) {
        _update(const LoginState()); // Dibatalkan user, bukan error
        return null;
      }

      final result = await _loginWithGoogle(idToken);
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
    } on OAuthNotConfiguredException catch (e) {
      _update(LoginState(status: LoginStatus.error, errorMessage: e.message));
      return false;
    } catch (_) {
      _update(const LoginState(
        status: LoginStatus.error,
        errorMessage: 'Masuk dengan Google gagal. Coba lagi.',
      ));
      return false;
    }
  }

  Future<bool?> submitWithApple() async {
    _update(const LoginState(status: LoginStatus.submitting));

    try {
      final credential = await _oauthSignInService.signInWithApple();
      if (credential == null) {
        _update(const LoginState());
        return null;
      }

      final result = await _loginWithApple(
        identityToken: credential.identityToken,
        fullName: credential.fullName,
      );
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
    } on OAuthNotConfiguredException catch (e) {
      _update(LoginState(status: LoginStatus.error, errorMessage: e.message));
      return false;
    } catch (_) {
      _update(const LoginState(
        status: LoginStatus.error,
        errorMessage: 'Masuk dengan Apple gagal. Coba lagi.',
      ));
      return false;
    }
  }
}
