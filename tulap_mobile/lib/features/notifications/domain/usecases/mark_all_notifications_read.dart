import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsRead {
  final NotificationsRepository _repository;
  MarkAllNotificationsRead(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.markAllRead();
  }
}
