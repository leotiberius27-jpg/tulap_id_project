import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// DioClient
/// ----------------------------------------------------------------------
/// HTTP client terpusat untuk seluruh komunikasi ke backend NestJS.
/// Menyisipkan Access Token JWT secara otomatis ke setiap request lewat
/// interceptor, dan menangani refresh token saat menerima 401.
/// ----------------------------------------------------------------------
class DioClient {
  final Dio dio;
  final FlutterSecureStorage _secureStorage;
  final String baseUrl;

  DioClient({required this.baseUrl, FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Access token kedaluwarsa - coba refresh sekali, lalu ulangi
          // request asli. Jika refresh juga gagal, teruskan error apa
          // adanya agar UI mengarahkan user ke halaman login.
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(baseUrl: baseUrl),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await _secureStorage.write(key: 'access_token', value: newAccessToken);
      await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}
