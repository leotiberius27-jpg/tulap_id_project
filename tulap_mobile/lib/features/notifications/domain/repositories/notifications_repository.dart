import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

class NotificationListResult {
  final List<NotificationEntity> items;
  final int unreadCount;

  const NotificationListResult({required this.items, required this.unreadCount});
}

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationListResult>> getNotifications();
  Future<Either<Failure, void>> markRead(String id);
  Future<Either<Failure, void>> markAllRead();
}
