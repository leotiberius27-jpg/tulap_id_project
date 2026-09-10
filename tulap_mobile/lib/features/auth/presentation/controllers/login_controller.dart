import 'package:flutter/foundation.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/is_biometric_login_enabled.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_facebook.dart';
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
  final LoginWithApple? _loginWithApple;
  final LoginWithFacebook? _loginWithFacebook;
  final OAuthSignInService _oauthSignInService;
  final RestoreBiometricSession? _restoreBiometricSession;
  final IsBiometricLoginEnabled? _isBiometricLoginEnabled;
  final BiometricAuthService? _biometricAuthService;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  LoginController({
    required Login login,
    required LoginWithGoogle loginWithGoogle,
    LoginWithApple? loginWithApple,
    LoginWithFacebook? loginWithFacebook,
    required OAuthSignInService oauthSignInService,
    RestoreBiometricSession? restoreBiometricSession,
    IsBiometricLoginEnabled? isBiometricLoginEnabled,
    BiometricAuthService? biometricAuthService,
  }) : _login = login,
       _loginWithGoogle = loginWithGoogle,
       _loginWithApple = loginWithApple,
       _loginWithFacebook = loginWithFacebook,
       _oauthSignInService = oauthSignInService,
       _restoreBiometricSession = restoreBiometricSession,
       _isBiometricLoginEnabled = isBiometricLoginEnabled,
       _biometricAuthService = biometricAuthService {
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (_isBiometricLoginEnabled != null && _restoreBiometricSession != null) {
      final enabled = await _isBiometricLoginEnabled();
      final hardwareAvailable = _biometricAuthService != null
          ? await _biometricAuthService.isAvailable()
          : true;
      if (enabled && hardwareAvailable) {
        _update(_state.copyWith(biometricAvailable: true));
      }
    }
  }

  void _update(LoginState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Memverifikasi sidik jari/biometrik fisik terlebih dahulu.
  /// HANYA jika sidik jari teruji cocok/sesuai, sesi akun dipulihkan
  /// dan user diizinkan masuk ke Beranda.
  Future<bool> submitBiometric() async {
    if (_restoreBiometricSession == null) return false;

    // 1. Verifikasi hardware sensor sidik jari terlebih dahulu
    if (_biometricAuthService != null) {
      final isAvailable = await _biometricAuthService.isAvailable();
      if (!isAvailable) {
        _update(
          _state.copyWith(
            status: LoginStatus.error,
            errorMessage: 'Sensor sidik jari tidak tersedia pada perangkat.',
          ),
        );
        return false;
      }

      _update(
        _state.copyWith(status: LoginStatus.submitting, errorMessage: null),
      );

      final verified = await _biometricAuthService.authenticate(
        'Pindai sidik jari Anda untuk memverifikasi dan masuk ke Tulap.id',
      );

      if (!verified) {
        _update(
          _state.copyWith(
            status: LoginStatus.error,
            errorMessage: 'Sidik jari tidak cocok atau verifikasi dibatalkan.',
          ),
        );
        return false;
      }
    } else {
      _update(
        _state.copyWith(status: LoginStatus.submitting, errorMessage: null),
      );
    }

    // 2. Jika sensor sidik jari lolos pengujian & sesuai, pulihkan sesi akun
    try {
      final user = await _restoreBiometricSession();
      if (user != null) {
        _update(_state.copyWith(status: LoginStatus.idle, user: user));
        return true;
      }
      _update(
        _state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Sesi sidik jari tidak ditemukan. Silakan masuk dengan email & kata sandi.',
        ),
      );
      return false;
    } catch (_) {
      _update(
        _state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Gagal memulihkan sesi biometrik. Silakan coba lagi.',
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
  Future<bool?> submitWithGoogle({bool forceAccountChooser = false}) async {
    _update(const LoginState(status: LoginStatus.submitting));

    try {
      final googleData = await _oauthSignInService.signInWithGoogle(
        forceAccountChooser: forceAccountChooser,
      );
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
    if (_loginWithApple == null) return false;
    _update(const LoginState(status: LoginStatus.submitting));

    try {
      final credential = await _oauthSignInService.signInWithApple();
      if (credential == null) {
        _update(const LoginState());
        return null;
      }

      final result = await _loginWithApple!(
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

  Future<bool?> submitWithFacebook() async {
    _update(const LoginState(status: LoginStatus.submitting));

    try {
      final credential = await _oauthSignInService.signInWithFacebook();
      if (credential == null) {
        _update(const LoginState());
        return null;
      }

      if (_loginWithFacebook != null) {
        final result = await _loginWithFacebook!(
          accessToken: credential.accessToken,
          email: credential.email,
          fullName: credential.displayName,
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
      }
      return false;
    } on OAuthNotConfiguredException catch (e) {
      _update(LoginState(status: LoginStatus.error, errorMessage: e.message));
      return false;
    } catch (_) {
      _update(
        const LoginState(
          status: LoginStatus.error,
          errorMessage: 'Masuk dengan Facebook gagal. Coba lagi.',
        ),
      );
      return false;
    }
  }
}
