import '../repositories/auth_repository.dart';

/// Logout (UseCase)
/// ----------------------------------------------------------------------
/// Menghapus sesi tersimpan. Dipanggil dari layar Akun - setelah ini,
/// `AuthGate` (dievaluasi ulang lewat navigasi ke halaman baru) akan
/// mengarahkan user kembali ke Login.
/// ----------------------------------------------------------------------
class Logout {
  final AuthRepository _repository;

  Logout(this._repository);

  Future<void> call() => _repository.logout();
}
