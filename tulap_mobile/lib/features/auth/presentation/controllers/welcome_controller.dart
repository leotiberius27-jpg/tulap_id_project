import 'package:flutter/foundation.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/get_biometric_greeting_user.dart';
import '../../domain/usecases/restore_biometric_session.dart';

class WelcomeState {
  final bool isOnline;
  final AuthUserEntity? greetingUser;
  final bool biometricAvailable;
  final bool isRestoringBiometric;
  final String? biometricError;

  const WelcomeState({
    this.isOnline = true,
    this.greetingUser,
    this.biometricAvailable = false,
    this.isRestoringBiometric = false,
    this.biometricError,
  });

  WelcomeState copyWith({
    bool? isOnline,
    AuthUserEntity? greetingUser,
    bool? biometricAvailable,
    bool? isRestoringBiometric,
    String? biometricError,
  }) {
    return WelcomeState(
      isOnline: isOnline ?? this.isOnline,
      greetingUser: greetingUser ?? this.greetingUser,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      isRestoringBiometric: isRestoringBiometric ?? this.isRestoringBiometric,
      biometricError: biometricError,
    );
  }
}

/// WelcomeController
/// ----------------------------------------------------------------------
/// Layar Welcome (sebelum form Login) - status "Online" NYATA (bukan
/// hiasan, lihat NetworkInfo), sapaan nama dari salinan sesi biometrik
/// jika pernah diaktifkan (lihat GetBiometricGreetingUser -
/// AuthLocalDataSource.getBiometricBackupUser), dan tombol sidik jari
/// yang HANYA aktif jika hardware perangkat mendukung DAN ada salinan
/// biometrik tersimpan (biometrik tidak pernah bisa dipakai untuk "buat
/// akun baru", murni jalan pintas memulihkan sesi yang sudah pernah ada).
/// ----------------------------------------------------------------------
class WelcomeController extends ChangeNotifier {
  final NetworkInfo _networkInfo;
  final GetBiometricGreetingUser _getBiometricGreetingUser;
  final RestoreBiometricSession _restoreBiometricSession;
  final BiometricAuthService _biometricAuthService;

  WelcomeState _state = const WelcomeState();
  WelcomeState get state => _state;

  WelcomeController({
    required NetworkInfo networkInfo,
    required GetBiometricGreetingUser getBiometricGreetingUser,
    required RestoreBiometricSession restoreBiometricSession,
    required BiometricAuthService biometricAuthService,
  }) : _networkInfo = networkInfo,
       _getBiometricGreetingUser = getBiometricGreetingUser,
       _restoreBiometricSession = restoreBiometricSession,
       _biometricAuthService = biometricAuthService {
    _load();
  }

  void _update(WelcomeState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _load() async {
    final isOnline = await _networkInfo.isConnected;
    final greetingUser = await _getBiometricGreetingUser();
    final biometricAvailable =
        greetingUser != null && await _biometricAuthService.isAvailable();

    _update(
      _state.copyWith(
        isOnline: isOnline,
        greetingUser: greetingUser,
        biometricAvailable: biometricAvailable,
      ),
    );
  }

  /// Memicu prompt biometrik perangkat lalu memulihkan sesi tersimpan
  /// jika berhasil. Mengembalikan user hasil pemulihan (null jika
  /// dibatalkan/gagal) - pemanggil (WelcomePage) yang menavigasikan ke
  /// MainShell.
  Future<AuthUserEntity?> authenticateWithBiometric() async {
    _update(_state.copyWith(isRestoringBiometric: true, biometricError: null));

    final verified = await _biometricAuthService.authenticate(
      'Verifikasi sidik jari/wajah untuk masuk ke Tulap.id',
    );

    if (!verified) {
      _update(
        _state.copyWith(
          isRestoringBiometric: false,
          biometricError: 'Verifikasi biometrik dibatalkan atau gagal.',
        ),
      );
      return null;
    }

    final user = await _restoreBiometricSession();
    _update(
      _state.copyWith(
        isRestoringBiometric: false,
        biometricError: user == null
            ? 'Sesi tersimpan tidak ditemukan. Masuk dengan kata sandi.'
            : null,
      ),
    );
    return user;
  }
}
