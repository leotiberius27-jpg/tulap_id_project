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
}
