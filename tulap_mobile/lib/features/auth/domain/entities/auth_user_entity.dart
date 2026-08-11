/// AuthUserEntity
/// ----------------------------------------------------------------------
/// Representasi murni data user yang sedang login di layer domain.
/// Field selaras dengan objek `user` pada response `POST /auth/login`
/// backend (lihat AuthService.login).
/// ----------------------------------------------------------------------
class AuthUserEntity {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? instansiName;

  const AuthUserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.instansiName,
  });
}
