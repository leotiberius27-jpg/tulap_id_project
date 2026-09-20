import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

/// AuthRemoteDataSource
/// ----------------------------------------------------------------------
class AuthRemoteDataSource {
  final DioClient _dioClient;
  AuthRemoteDataSource(this._dioClient);

  /// Mengembalikan response mentah `POST /auth/login`
  /// ({ accessToken, refreshToken, user }) - parsing ke model dilakukan
  /// di repository agar datasource ini tetap tipis, sesuai pola
  /// datasource lain di proyek ini.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Registrasi mandiri (layar "Daftar") - backend SELALU membuat akun
  /// ber-role PEGAWAI dan langsung mengembalikan token (auto-login),
  /// sama seperti response `login()`.
  Future<Map<String, dynamic>> registerSelf({
    required String fullName,
    required String email,
    required String password,
    required String instansiName,
    String? phoneNumber,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/register-self',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'instansiName': instansiName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String email) async {
    await _dioClient.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dioClient.dio.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _dioClient.dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /auth/firebase-login - "pintu depan" Android: menukar Firebase
  /// ID Token (dari Email/Password ATAU Google Sign-In lewat Firebase
  /// Client SDK, lihat AuthRepositoryImpl.login/loginWithGoogle) dengan
  /// sesi Tulap.id asli. Lihat AuthService.loginWithFirebase di backend.
  Future<Map<String, dynamic>> loginWithFirebase(String firebaseIdToken) async {
    final response = await _dioClient.dio.post(
      '/auth/firebase-login',
      data: {'idToken': firebaseIdToken},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/apple',
      data: {
        'identityToken': identityToken,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) async {
    final response = await _dioClient.dio.post(
      '/auth/facebook',
      data: {
        'accessToken': accessToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /users/me - update profil DIRI SENDIRI (nama, telepon,
  /// instansi, NIP). Tidak termasuk foto - lihat `uploadProfilePhoto()`.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? instansiName,
    String? nip,
  }) async {
    final response = await _dioClient.dio.patch(
      '/users/me',
      data: {
        'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (instansiName != null) 'instansiName': instansiName,
        if (nip != null) 'nip': nip,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /users/me/photo - unggah foto profil dari file lokal (hasil
  /// kamera/galeri) ke S3, mengembalikan user dengan `photoUrl` https
  /// permanen (bukan path lokal device).
  Future<Map<String, dynamic>> uploadProfilePhoto(String localFilePath) async {
    final fileName = localFilePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localFilePath, filename: fileName),
    });
    final response = await _dioClient.dio.post(
      '/users/me/photo',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /users/me/photo - hapus foto profil sendiri.
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    final response = await _dioClient.dio.delete('/users/me/photo');
    return response.data as Map<String, dynamic>;
  }

  /// GET /users/me - profil lengkap diri sendiri langsung dari server,
  /// dipakai untuk menyegarkan cache sesi lokal saat app dibuka (lihat
  /// AuthSessionManager.refreshFromServer()).
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dioClient.dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }
}
