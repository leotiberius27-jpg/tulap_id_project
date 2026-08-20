import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.instansiName,
    super.nip,
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
    );
  }
}
