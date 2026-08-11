import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetActiveTasks {
  final TaskRepository _repository;

  GetActiveTasks(this._repository);

  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getActiveTasks();
  }
}
