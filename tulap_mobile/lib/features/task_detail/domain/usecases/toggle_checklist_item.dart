import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class ToggleChecklistItem {
  final TaskRepository _repository;
  ToggleChecklistItem(this._repository);

  Future<Either<Failure, ChecklistItemEntity>> call({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  }) {
    return _repository.toggleChecklistItem(
      taskId: taskId,
      itemId: itemId,
      isCompleted: isCompleted,
    );
  }
}
