import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

/// GetCurrentSession (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil main.dart saat app dibuka untuk memutuskan rute awal:
/// mengembalikan null jika belum ada sesi tersimpan (arahkan ke
/// Login), atau data user jika sudah pernah login sebelumnya (arahkan
/// langsung ke Beranda).
/// ----------------------------------------------------------------------
class GetCurrentSession {
  final AuthRepository _repository;

  GetCurrentSession(this._repository);

  Future<AuthUserEntity?> call() {
    return _repository.getStoredUser();
  }
}
