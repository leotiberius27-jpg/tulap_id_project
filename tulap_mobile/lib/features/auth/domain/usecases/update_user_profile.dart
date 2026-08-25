import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../entities/auth_user_entity.dart';
import '../repositories/auth_repository.dart';

/// UpdateUserProfile
/// ----------------------------------------------------------------------
/// Usecase untuk memperbarui profil pengguna saat ini (Nama, No HP,
/// Instansi, NIP, Foto) dan menyimpan perubahan ke sesi lokal terpusat,
/// serta memperbarui state sesi global terpusat (AuthSessionManager).
/// ----------------------------------------------------------------------
class UpdateUserProfile {
  final AuthRepository _repository;
  final AuthSessionManager? _sessionManager;

  UpdateUserProfile(this._repository, [this._sessionManager]);

  Future<Either<Failure, AuthUserEntity>> call({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
    String? photoUrl,
  }) async {
    final result = await _repository.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      instansiName: instansiName,
      nip: nip,
      photoUrl: photoUrl,
    );

    result.fold(
      (_) {},
      (updatedUser) {
        _sessionManager?.updateUser(updatedUser);
      },
    );

    return result;
  }
}
