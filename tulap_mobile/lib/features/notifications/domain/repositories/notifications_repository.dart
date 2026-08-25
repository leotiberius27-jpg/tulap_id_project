import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

class NotificationListResult {
  final List<NotificationEntity> items;
  final int unreadCount;

  const NotificationListResult({
    required this.items,
    required this.unreadCount,
  });
}

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationListResult>> getNotifications({
    NotificationCategory? category,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();

  Future<Either<Failure, int>> deleteReadNotifications();

  Future<Either<Failure, void>> createOrUpdateNotification(
    NotificationEntity notification,
  );

  Future<Either<Failure, void>> deleteNotification(String id);

  Stream<int> get unreadCountStream;
}
