import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

/// SubmitTaskForVerification (UseCase)
/// ----------------------------------------------------------------------
/// Dipanggil saat pegawai menekan "Kirim Tugas". Melakukan PRE-CHECK
/// optimis di client (`task.isReadyToSubmit`) sebelum memanggil
/// repository, supaya pegawai dapat feedback instan tanpa menunggu
/// roundtrip network untuk kasus yang jelas-jelas belum lengkap.
/// Validasi FINAL & otoritatif tetap dilakukan backend (lihat
/// TasksService.submitForVerification di backend).
/// ----------------------------------------------------------------------
class SubmitTaskForVerification {
  final TaskRepository _repository;
  SubmitTaskForVerification(this._repository);

  Future<Either<Failure, TaskEntity>> call(TaskEntity task) {
    if (!task.isReadyToSubmit) {
      return Future.value(
        Left(ChecklistIncompleteFailure(task.incompleteMandatoryItems)),
      );
    }
    return _repository.submitForVerification(task.id);
  }
}

class ChecklistIncompleteFailure extends Failure {
  final List<dynamic> incompleteItems;
  ChecklistIncompleteFailure(this.incompleteItems)
    : super('${incompleteItems.length} bukti wajib belum lengkap.');
}
