import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class DeleteReadNotifications {
  final NotificationsRepository _repository;
  DeleteReadNotifications(this._repository);

  Future<Either<Failure, int>> call() {
    return _repository.deleteReadNotifications();
  }
}
