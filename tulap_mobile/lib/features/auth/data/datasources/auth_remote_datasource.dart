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
}
