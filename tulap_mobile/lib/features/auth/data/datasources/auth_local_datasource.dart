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

  Future<AuthUserModel> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUserModel user,
  }) async {
    // Ambil profil tersimpan lokal sebelumnya untuk mempertahankan foto & kustomisasi
    final existingRegistered = await getRegisteredUserProfile(user.email);

    final effectivePhotoUrl =
        (user.photoUrl != null && user.photoUrl!.trim().isNotEmpty)
            ? user.photoUrl
            : existingRegistered?.photoUrl;

    final effectiveInstansi =
        (user.instansiName != null && user.instansiName!.trim().isNotEmpty)
            ? user.instansiName
            : existingRegistered?.instansiName;

    final effectiveNip =
        (user.nip != null && user.nip!.trim().isNotEmpty)
            ? user.nip
            : existingRegistered?.nip;

    final effectivePhone =
        (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty)
            ? user.phoneNumber
            : existingRegistered?.phoneNumber;

    final cleanedName = user.fullName
        .replaceAll(
          RegExp(
            r'\s*\((?:Google|Google User|Apple|Apple User)\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\bGoogle User\b', caseSensitive: false), '')
        .trim();

    final effectiveFullName =
        (cleanedName.isNotEmpty)
            ? cleanedName
            : (existingRegistered?.fullName.isNotEmpty == true
                ? existingRegistered!.fullName
                : user.fullName);

    final finalUser = user.copyWith(
      fullName: effectiveFullName,
      photoUrl: effectivePhotoUrl,
      instansiName: effectiveInstansi,
      nip: effectiveNip,
      phoneNumber: effectivePhone,
    );

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(
      key: _userProfileKey,
      value: jsonEncode(finalUser.toStorageMap()),
    );
    await saveRegisteredUserProfile(finalUser);
    return finalUser;
  }

  Future<void> saveRegisteredUserProfile(AuthUserModel user) async {
    final key = 'reg_profile_${user.email.toLowerCase().trim()}';
    await _secureStorage.write(
      key: key,
      value: jsonEncode(user.toStorageMap()),
    );
  }

  Future<AuthUserModel?> getRegisteredUserProfile(String email) async {
    final key = 'reg_profile_${email.toLowerCase().trim()}';
    final raw = await _secureStorage.read(key: key);
    if (raw == null) return null;
    try {
      return AuthUserModel.fromStorageMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<AuthUserModel?> getStoredUser() async {
    final raw = await _secureStorage.read(key: _userProfileKey);
    if (raw == null) return null;
    return AuthUserModel.fromStorageMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Memperbarui profil user di penyimpanan aman (nama, nomor telepon, instansi, dll.)
  /// dan memperbarui salinan cadangan registrasi lokal.
  Future<void> updateUserProfile(AuthUserModel updatedUser) async {
    await _secureStorage.write(
      key: _userProfileKey,
      value: jsonEncode(updatedUser.toStorageMap()),
    );
    await saveRegisteredUserProfile(updatedUser);
  }

  /// Menghapus seluruh sesi tersimpan (logout) - setelah ini
  /// `getStoredUser()` kembali mengembalikan null, sehingga `AuthGate`
  /// mengarahkan user ke Login lagi.
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userProfileKey);
  }
}
