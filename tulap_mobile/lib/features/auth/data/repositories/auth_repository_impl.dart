import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';

/// Gagal login (kredensial salah, akun nonaktif, atau masalah jaringan)
/// - pesan diambil langsung dari response backend agar sesuai Bagian 17
/// (UX Copywriting: error harus jelas & actionable, bukan generik).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final user = AuthUserModel.fromLoginJson(
        json['user'] as Map<String, dynamic>,
      );

      await _localDataSource.saveSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: user,
      );

      return Right(user);
    } on DioException catch (e) {
      return Left(AuthFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<AuthUserEntity?> getStoredUser() {
    return _localDataSource.getStoredUser();
  }

  @override
  Future<void> logout() {
    return _localDataSource.clearSession();
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
  }
}
