import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadNotificationCount {
  final NotificationsRepository _repository;
  GetUnreadNotificationCount(this._repository);

  Future<Either<Failure, int>> call() {
    return _repository.getUnreadCount();
  }

  Stream<int> get stream => _repository.unreadCountStream;
}
