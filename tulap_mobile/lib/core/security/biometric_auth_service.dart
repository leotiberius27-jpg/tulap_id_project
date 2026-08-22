import 'package:local_auth/local_auth.dart';

/// BiometricAuthService
/// ----------------------------------------------------------------------
/// Pembungkus tipis di atas package `local_auth` (sidik jari/wajah
/// bawaan perangkat, BUKAN otentikasi ke server - murni gerbang lokal
/// sebelum memulihkan sesi yang sudah tersimpan, lihat
/// AuthLocalDataSource.restoreBiometricSession).
/// ----------------------------------------------------------------------
class BiometricAuthService {
  final LocalAuthentication _localAuth;

  BiometricAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Meminta verifikasi biometrik perangkat. Mengembalikan `true` hanya
  /// jika user benar-benar berhasil diverifikasi - setiap exception
  /// (dibatalkan user, hardware terkunci, dsb) dianggap gagal, bukan
  /// dilempar ke pemanggil.
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // izinkan fallback PIN/pola perangkat
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
