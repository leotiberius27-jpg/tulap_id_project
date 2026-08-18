import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

/// StartTask (UseCase)
/// ----------------------------------------------------------------------
/// Memindahkan tugas dari status DRAFT ke ONGOING di backend saat
/// pegawai menekan "Mulai Tugas" di Detail Tugas.
/// ----------------------------------------------------------------------
class StartTask {
  final TaskRepository _repository;

  StartTask(this._repository);

  Future<Either<Failure, TaskEntity>> call(String taskId) {
    return _repository.startTask(taskId);
  }
}
