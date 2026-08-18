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
}
