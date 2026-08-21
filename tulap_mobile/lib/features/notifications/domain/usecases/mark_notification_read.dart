import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationRead {
  final NotificationsRepository _repository;
  MarkNotificationRead(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.markRead(id);
  }
}
