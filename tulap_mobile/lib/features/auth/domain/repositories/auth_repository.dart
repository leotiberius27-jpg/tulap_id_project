import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';

/// AuthRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class AuthRepository {
  /// Login ke backend, lalu menyimpan Access/Refresh Token beserta
  /// profil user ke penyimpanan aman (flutter_secure_storage) jika
  /// berhasil - sumber kebenaran sesi untuk seluruh app sesudahnya.
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  });

  /// Membaca profil user dari sesi yang tersimpan lokal (TANPA
  /// panggilan network) - dipakai saat app dibuka untuk menentukan
  /// apakah user diarahkan ke Login atau langsung ke Beranda, dan untuk
  /// mengisi header Beranda (nama, instansi).
  Future<AuthUserEntity?> getStoredUser();

  /// Menghapus sesi tersimpan (logout) - tidak butuh panggilan network,
  /// backend tidak menyimpan state sesi server-side untuk alur ini.
  /// TIDAK menghapus salinan biometrik (lihat `disableBiometricLogin`
  /// untuk itu) - sengaja terpisah, lihat AuthLocalDataSource.
  Future<void> logout();

  /// Registrasi mandiri (layar "Daftar") - langsung login otomatis jika
  /// berhasil, sama seperti alur `login()`.
  Future<Either<Failure, AuthUserEntity>> selfRegister({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  });

  Future<Either<Failure, String>> forgotPassword(String email);

  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  });

  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  });

  /// Apakah "Masuk Cepat dengan Biometrik" sedang aktif di perangkat ini.
  Future<bool> isBiometricLoginEnabled();

  /// Mengaktifkan biometrik - menyalin sesi AKTIF saat ini (harus sudah
  /// login) ke slot biometrik terpisah.
  Future<void> enableBiometricLogin();

  Future<void> disableBiometricLogin();

  /// Nama pegawai dari salinan biometrik, untuk sapaan WelcomePage -
  /// null jika biometrik belum pernah diaktifkan di perangkat ini.
  Future<AuthUserEntity?> getBiometricGreetingUser();

  /// Memulihkan sesi dari salinan biometrik (dipanggil SETELAH
  /// `local_auth` berhasil memverifikasi) - null jika tidak ada salinan
  /// tersimpan.
  Future<AuthUserEntity?> restoreBiometricSession();

  /// Memperbarui informasi profil pengguna (Nama, Nomor Telepon, Instansi, NIP, Foto)
  /// dan memperbarui sesi lokal.
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  });
}
