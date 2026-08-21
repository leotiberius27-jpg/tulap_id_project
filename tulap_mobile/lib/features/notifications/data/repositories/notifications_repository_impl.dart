import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

/// Notifikasi TIDAK offline-first (berbeda dari task_detail/geotag_camera) -
/// murni bacaan real-time dari server, tidak ada nilai menyimpannya lokal
/// karena notifikasi baru justru datang SAAT online. Kegagalan network di
/// sini hanya berarti daftar belum bisa dimuat, bukan data hilang.
class NotificationFetchFailure extends Failure {
  const NotificationFetchFailure([
    super.message = 'Notifikasi belum bisa dimuat. Coba lagi.',
  ]);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl({required NotificationsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, NotificationListResult>> getNotifications() async {
    try {
      final result = await _remoteDataSource.getNotifications();
      return Right(
        NotificationListResult(items: result.items, unreadCount: result.unreadCount),
      );
    } on DioException {
      return const Left(NotificationFetchFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    try {
      await _remoteDataSource.markRead(id);
      return const Right(null);
    } on DioException {
      return const Left(NotificationFetchFailure('Gagal menandai notifikasi.'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _remoteDataSource.markAllRead();
      return const Right(null);
    } on DioException {
      return const Left(NotificationFetchFailure('Gagal menandai semua notifikasi.'));
    }
  }
}
