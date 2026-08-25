import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications {
  final NotificationsRepository _repository;
  GetNotifications(this._repository);

  Future<Either<Failure, NotificationListResult>> call({
    NotificationCategory? category,
  }) {
    return _repository.getNotifications(category: category);
  }
}
