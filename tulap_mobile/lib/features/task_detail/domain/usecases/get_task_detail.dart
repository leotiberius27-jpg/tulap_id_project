import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskDetail {
  final TaskRepository _repository;
  GetTaskDetail(this._repository);

  Future<Either<Failure, TaskEntity>> call(String taskId) {
    return _repository.getTaskDetail(taskId);
  }
}
