import '../../../../core/session/auth_session_manager.dart';
import '../repositories/auth_repository.dart';

/// Logout (UseCase)
/// ----------------------------------------------------------------------
/// Menghapus sesi tersimpan. Dipanggil dari layar Akun - setelah ini,
/// `AuthGate` (dievaluasi ulang lewat navigasi ke halaman baru) akan
/// mengarahkan user kembali ke Login.
/// ----------------------------------------------------------------------
class Logout {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  Logout(this._repository, [this._sessionManager]);

  Future<void> call() async {
    await _repository.logout();
    _sessionManager?.clearSession();
  }
}
