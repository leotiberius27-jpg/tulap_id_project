import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications {
  final NotificationsRepository _repository;
  GetNotifications(this._repository);

  Future<Either<Failure, NotificationListResult>> call() {
    return _repository.getNotifications();
  }
}
