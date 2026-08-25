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
  final String? nip;
  final String? phoneNumber;
  final String? photoUrl;
  final String? authProvider;

  const AuthUserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.instansiName,
    this.nip,
    this.phoneNumber,
    this.photoUrl,
    this.authProvider,
  });

  AuthUserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? instansiName,
    String? nip,
    String? phoneNumber,
    String? photoUrl,
    String? authProvider,
  }) {
    return AuthUserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      instansiName: instansiName ?? this.instansiName,
      nip: nip ?? this.nip,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUserEntity &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.role == role &&
        other.instansiName == instansiName &&
        other.nip == nip &&
        other.phoneNumber == phoneNumber &&
        other.photoUrl == photoUrl &&
        other.authProvider == authProvider;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        email,
        role,
        instansiName,
        nip,
        phoneNumber,
        photoUrl,
        authProvider,
      );
}

