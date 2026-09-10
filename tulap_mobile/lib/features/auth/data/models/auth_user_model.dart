import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.instansiName,
    super.nip,
    super.phoneNumber,
    super.photoUrl,
    super.authProvider,
  });

  /// Parsing dari objek `user` pada response `POST /auth/login` backend
  /// (lihat AuthService.login).
  factory AuthUserModel.fromLoginJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      instansiName: json['instansiName'] as String?,
      nip: json['nip'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      authProvider: json['authProvider'] as String?,
    );
  }

  /// Parsing dari response `PATCH/POST/DELETE /users/me*` backend
  /// (UsersService._safeUserSelect()) - berbeda dari `fromLoginJson()`:
  /// `role` di sini objek `{ id, name }`, bukan string langsung.
  factory AuthUserModel.fromUserJson(Map<String, dynamic> json) {
    final roleField = json['role'];
    final roleName = roleField is Map
        ? roleField['name'] as String
        : roleField as String;
    return AuthUserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: roleName,
      instansiName: json['instansiName'] as String?,
      nip: json['nip'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  @override
  AuthUserModel copyWith({
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
    return AuthUserModel(
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

  /// Untuk disimpan sebagai JSON string di flutter_secure_storage.
  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'instansiName': instansiName,
      'nip': nip,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
    };
  }

  factory AuthUserModel.fromStorageMap(Map<String, dynamic> map) {
    return AuthUserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      instansiName: map['instansiName'] as String?,
      nip: map['nip'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      authProvider: map['authProvider'] as String?,
    );
  }

  factory AuthUserModel.fromEntity(AuthUserEntity entity) {
    return AuthUserModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      role: entity.role,
      instansiName: entity.instansiName,
      nip: entity.nip,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      authProvider: entity.authProvider,
    );
  }
}
