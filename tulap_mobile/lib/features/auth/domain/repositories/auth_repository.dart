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

  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  });

  /// Memperbarui informasi profil pengguna (Nama, Nomor Telepon, Instansi, NIP, Foto)
  /// dan memperbarui sesi lokal.
  Future<Either<Failure, AuthUserEntity>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  });

  /// Mengambil profil TERBARU langsung dari server (GET /users/me) dan
  /// menimpa cache lokal dengannya - null jika gagal (offline, dsb),
  /// TANPA melempar/menghapus sesi yang sudah ada (best-effort refresh).
  /// Menutup celah: perubahan data yang terjadi di luar flow app (mis.
  /// perbaikan data langsung di database) sebelumnya tidak pernah
  /// tercermin di cache lokal sampai user logout/login manual.
  Future<AuthUserEntity?> refreshStoredUserFromServer();
}
