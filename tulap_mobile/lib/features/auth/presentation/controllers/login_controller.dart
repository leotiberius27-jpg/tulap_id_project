import 'package:flutter/foundation.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/is_biometric_login_enabled.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/restore_biometric_session.dart';

enum LoginStatus { idle, submitting, error }

class LoginState {
  final LoginStatus status;
  final AuthUserEntity? user;
  final String? errorMessage;
  final bool biometricAvailable;

  const LoginState({
    this.status = LoginStatus.idle,
    this.user,
    this.errorMessage,
    this.biometricAvailable = false,
  });

  LoginState copyWith({
    LoginStatus? status,
    AuthUserEntity? user,
    String? errorMessage,
    bool? biometricAvailable,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    );
  }
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
  final RestoreBiometricSession? _restoreBiometricSession;
  final IsBiometricLoginEnabled? _isBiometricLoginEnabled;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  LoginController({
    required Login login,
    required LoginWithGoogle loginWithGoogle,
    required LoginWithApple loginWithApple,
    required OAuthSignInService oauthSignInService,
    RestoreBiometricSession? restoreBiometricSession,
    IsBiometricLoginEnabled? isBiometricLoginEnabled,
  }) : _login = login,
       _loginWithGoogle = loginWithGoogle,
       _loginWithApple = loginWithApple,
       _oauthSignInService = oauthSignInService,
       _restoreBiometricSession = restoreBiometricSession,
       _isBiometricLoginEnabled = isBiometricLoginEnabled {
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (_isBiometricLoginEnabled != null && _restoreBiometricSession != null) {
      final enabled = await _isBiometricLoginEnabled();
      if (enabled) {
        _update(_state.copyWith(biometricAvailable: true));
      }
    }
  }

  void _update(LoginState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> submitBiometric() async {
    if (_restoreBiometricSession == null) return false;
    _update(
      _state.copyWith(status: LoginStatus.submitting, errorMessage: null),
    );

    try {
      final user = await _restoreBiometricSession();
      if (user != null) {
        _update(_state.copyWith(status: LoginStatus.idle, user: user));
        return true;
      }
      _update(_state.copyWith(status: LoginStatus.idle));
      return false;
    } catch (_) {
      _update(
        _state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Verifikasi biometrik gagal atau dibatalkan.',
        ),
      );
      return false;
    }
  }

  Future<bool> submit({required String email, required String password}) async {
    _update(const LoginState(status: LoginStatus.submitting));

    final result = await _login(email: email, password: password);

    return result.fold(
      (failure) {
        _update(
          LoginState(status: LoginStatus.error, errorMessage: failure.message),
        );
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
      final googleData = await _oauthSignInService.signInWithGoogle();
      if (googleData == null) {
        _update(const LoginState()); // Dibatalkan user, bukan error
        return null;
      }

      final result = await _loginWithGoogle(
        idToken: googleData.idToken,
        email: googleData.email,
        displayName: googleData.displayName,
      );
      return result.fold(
        (failure) {
          _update(
            LoginState(
              status: LoginStatus.error,
              errorMessage: failure.message,
            ),
          );
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
      _update(
        const LoginState(
          status: LoginStatus.error,
          errorMessage: 'Masuk dengan Google gagal. Coba lagi.',
        ),
      );
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
          _update(
            LoginState(
              status: LoginStatus.error,
              errorMessage: failure.message,
            ),
          );
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
      _update(
        const LoginState(
          status: LoginStatus.error,
          errorMessage: 'Masuk dengan Apple gagal. Coba lagi.',
        ),
      );
      return false;
    }
  }
}
