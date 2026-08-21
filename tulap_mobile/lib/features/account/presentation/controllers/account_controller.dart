import 'package:flutter/foundation.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/disable_biometric_login.dart';
import '../../../auth/domain/usecases/enable_biometric_login.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../auth/domain/usecases/is_biometric_login_enabled.dart';
import '../../../auth/domain/usecases/logout.dart';

class AccountState {
  final AuthUserEntity? user;
  final bool isLoggingOut;
  final bool biometricHardwareAvailable;
  final bool biometricLoginEnabled;
  final bool isTogglingBiometric;

  const AccountState({
    this.user,
    this.isLoggingOut = false,
    this.biometricHardwareAvailable = false,
    this.biometricLoginEnabled = false,
    this.isTogglingBiometric = false,
  });

  AccountState copyWith({
    AuthUserEntity? user,
    bool? isLoggingOut,
    bool? biometricHardwareAvailable,
    bool? biometricLoginEnabled,
    bool? isTogglingBiometric,
  }) {
    return AccountState(
      user: user ?? this.user,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      biometricHardwareAvailable:
          biometricHardwareAvailable ?? this.biometricHardwareAvailable,
      biometricLoginEnabled: biometricLoginEnabled ?? this.biometricLoginEnabled,
      isTogglingBiometric: isTogglingBiometric ?? this.isTogglingBiometric,
    );
  }
}

class AccountController extends ChangeNotifier {
  final GetCurrentSession _getCurrentSession;
  final Logout _logout;
  final IsBiometricLoginEnabled _isBiometricLoginEnabled;
  final EnableBiometricLogin _enableBiometricLogin;
  final DisableBiometricLogin _disableBiometricLogin;
  final BiometricAuthService _biometricAuthService;

  AccountState _state = const AccountState();
  AccountState get state => _state;

  AccountController({
    required GetCurrentSession getCurrentSession,
    required Logout logout,
    required IsBiometricLoginEnabled isBiometricLoginEnabled,
    required EnableBiometricLogin enableBiometricLogin,
    required DisableBiometricLogin disableBiometricLogin,
    required BiometricAuthService biometricAuthService,
  })  : _getCurrentSession = getCurrentSession,
        _logout = logout,
        _isBiometricLoginEnabled = isBiometricLoginEnabled,
        _enableBiometricLogin = enableBiometricLogin,
        _disableBiometricLogin = disableBiometricLogin,
        _biometricAuthService = biometricAuthService {
    _load();
  }

  void _update(AccountState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _load() async {
    final user = await _getCurrentSession();
    final hardwareAvailable = await _biometricAuthService.isAvailable();
    final biometricEnabled = await _isBiometricLoginEnabled();
    _update(_state.copyWith(
      user: user,
      biometricHardwareAvailable: hardwareAvailable,
      biometricLoginEnabled: biometricEnabled,
    ));
  }

  /// Mengaktifkan/menonaktifkan "Masuk Cepat dengan Biometrik" - saat
  /// mengaktifkan, WAJIB verifikasi biometrik dulu (bukti bahwa
  /// perangkat ini benar dipegang pemilik akun) sebelum sesi disalin ke
  /// slot biometrik.
  Future<void> toggleBiometricLogin(bool enable) async {
    _update(_state.copyWith(isTogglingBiometric: true));

    if (enable) {
      final verified = await _biometricAuthService.authenticate(
        'Verifikasi untuk mengaktifkan Masuk Cepat dengan Biometrik',
      );
      if (verified) {
        await _enableBiometricLogin();
      }
    } else {
      await _disableBiometricLogin();
    }

    final biometricEnabled = await _isBiometricLoginEnabled();
    _update(_state.copyWith(
      isTogglingBiometric: false,
      biometricLoginEnabled: biometricEnabled,
    ));
  }

  Future<void> signOut() async {
    _update(_state.copyWith(isLoggingOut: true));
    await _logout();
    _update(_state.copyWith(isLoggingOut: false));
  }
}
