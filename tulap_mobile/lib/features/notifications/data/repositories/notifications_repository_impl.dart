import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_datasource.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationFetchFailure extends Failure {
  const NotificationFetchFailure([
    super.message = 'Notifikasi belum bisa dimuat. Coba lagi.',
  ]);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationLocalDataSource _localDataSource;
  final NotificationsRemoteDataSource? _remoteDataSource;
  final AuthSessionManager? _authSessionManager;
  final NetworkInfo? _networkInfo;

  final _unreadController = StreamController<int>.broadcast();

  NotificationsRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
    NotificationsRemoteDataSource? remoteDataSource,
    AuthSessionManager? authSessionManager,
    NetworkInfo? networkInfo,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _authSessionManager = authSessionManager,
        _networkInfo = networkInfo;

  String get _currentUserId =>
      _authSessionManager?.currentUser?.id ?? 'current_user';

  @override
  Stream<int> get unreadCountStream => _unreadController.stream;

  void _notifyUnreadChanged(int count) {
    if (!_unreadController.isClosed) {
      _unreadController.add(count);
    }
  }

  @override
  Future<Either<Failure, NotificationListResult>> getNotifications({
    NotificationCategory? category,
  }) async {
    try {
      final userId = _currentUserId;

      // 1. Ambil data lokal terlebih dahulu (Offline-First)
      final localItems = await _localDataSource.getNotifications(
        userId: userId,
        category: category,
      );
      final unreadCount = await _localDataSource.getUnreadCount(userId);
      _notifyUnreadChanged(unreadCount);

      // 2. Jika online dan remote tersedia, sinkronkan di background tanpa memblokir
      if (_remoteDataSource != null && _networkInfo != null) {
        final isConnected = await _networkInfo.isConnected;
        if (isConnected) {
          try {
            final remoteResult = await _remoteDataSource.getNotifications();
            // Simpan data remote ke lokal
            for (final item in remoteResult.items) {
              await _localDataSource.saveNotification(
                NotificationModel(
                  id: item.id,
                  userId: userId,
                  category: item.category,
                  type: item.type,
                  title: item.title,
                  message: item.message,
                  relatedEntityType: item.relatedEntityType,
                  relatedEntityId: item.relatedEntityId,
                  actionType: item.actionType,
                  actionPayload: item.actionPayload,
                  priority: item.priority,
                  isRead: item.isRead,
                  createdAt: item.createdAt,
                  readAt: item.readAt,
                ),
              );
            }
            final updatedLocal = await _localDataSource.getNotifications(
              userId: userId,
              category: category,
            );
            final updatedUnread = await _localDataSource.getUnreadCount(userId);
            _notifyUnreadChanged(updatedUnread);

            return Right(
              NotificationListResult(
                items: updatedLocal,
                unreadCount: updatedUnread,
              ),
            );
          } catch (_) {
            // Fallback graceful ke lokal jika fetch remote gagal
          }
        }
      }

      return Right(
        NotificationListResult(
          items: localItems,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      return Left(NotificationFetchFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _localDataSource.getUnreadCount(_currentUserId);
      _notifyUnreadChanged(count);
      return Right(count);
    } catch (e) {
      return Left(NotificationFetchFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    try {
      await _localDataSource.markAsRead(id);
      final count = await _localDataSource.getUnreadCount(_currentUserId);
      _notifyUnreadChanged(count);

      // Best-effort remote patch
      if (_remoteDataSource != null && _networkInfo != null) {
        final isConnected = await _networkInfo.isConnected;
        if (isConnected) {
          _remoteDataSource.markRead(id).catchError((_) {});
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(NotificationFetchFailure('Gagal menandai notifikasi.'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _localDataSource.markAllAsRead(_currentUserId);
      _notifyUnreadChanged(0);

      // Best-effort remote patch
      if (_remoteDataSource != null && _networkInfo != null) {
        final isConnected = await _networkInfo.isConnected;
        if (isConnected) {
          _remoteDataSource.markAllRead().catchError((_) {});
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(NotificationFetchFailure('Gagal menandai semua notifikasi.'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteReadNotifications() async {
    try {
      final deleted =
          await _localDataSource.deleteReadNotifications(_currentUserId);
      final count = await _localDataSource.getUnreadCount(_currentUserId);
      _notifyUnreadChanged(count);
      return Right(deleted);
    } catch (e) {
      return Left(NotificationFetchFailure('Gagal menghapus notifikasi.'));
    }
  }

  @override
  Future<Either<Failure, void>> createOrUpdateNotification(
    NotificationEntity notification,
  ) async {
    try {
      final userId = notification.userId.isNotEmpty
          ? notification.userId
          : _currentUserId;

      // De-duplikasi berdasarkan Tipe & Entity ID
      final existing = await _localDataSource.findExistingByType(
        userId: userId,
        type: notification.type,
        relatedEntityId: notification.relatedEntityId,
      );

      final model = NotificationModel(
        id: existing?.id ?? notification.id,
        userId: userId,
        category: notification.category,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        relatedEntityType: notification.relatedEntityType,
        relatedEntityId: notification.relatedEntityId,
        actionType: notification.actionType,
        actionPayload: notification.actionPayload,
        priority: notification.priority,
        isRead: false, // Update ke notifikasi baru mereset status unread
        createdAt: DateTime.now(),
        readAt: null,
      );

      await _localDataSource.saveNotification(model);
      final count = await _localDataSource.getUnreadCount(userId);
      _notifyUnreadChanged(count);

      return const Right(null);
    } catch (e) {
      return Left(NotificationFetchFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      await _localDataSource.deleteNotification(id);
      final count = await _localDataSource.getUnreadCount(_currentUserId);
      _notifyUnreadChanged(count);
      return const Right(null);
    } catch (e) {
      return Left(NotificationFetchFailure('Gagal menghapus notifikasi.'));
    }
  }
}
