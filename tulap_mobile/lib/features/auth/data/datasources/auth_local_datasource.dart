import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_user_model.dart';

/// AuthLocalDataSource
/// ----------------------------------------------------------------------
/// Menyimpan sesi login (Access/Refresh Token + profil user) di
/// flutter_secure_storage. Key 'access_token'/'refresh_token' SENGAJA
/// sama persis dengan yang dibaca DioClient - datasource ini adalah
/// SATU-SATUNYA penulis kedua key tsb, DioClient hanya membaca.
/// ----------------------------------------------------------------------
class AuthLocalDataSource {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userProfileKey = 'user_profile';

  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSource({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUserModel user,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(
      key: _userProfileKey,
      value: jsonEncode(user.toStorageMap()),
    );
  }

  Future<AuthUserModel?> getStoredUser() async {
    final raw = await _secureStorage.read(key: _userProfileKey);
    if (raw == null) return null;
    return AuthUserModel.fromStorageMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
