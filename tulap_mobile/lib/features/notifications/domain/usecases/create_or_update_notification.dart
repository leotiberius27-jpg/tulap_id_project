import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class CreateOrUpdateNotification {
  final NotificationsRepository _repository;
  CreateOrUpdateNotification(this._repository);

  Future<Either<Failure, void>> call(NotificationEntity notification) {
    return _repository.createOrUpdateNotification(notification);
  }
}
