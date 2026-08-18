import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import 'get_active_tasks.dart';

/// PickActiveTask (UseCase)
/// ----------------------------------------------------------------------
/// Memilih SATU tugas untuk disorot (Kartu Tugas Aktif di Beranda,
/// konteks tombol kamera tengah bottom nav), diprioritaskan dari yang
/// paling butuh perhatian pegawai: sedang berjalan/perlu revisi lebih
/// dulu, baru draft, baru menunggu verifikator. Tugas berstatus selesai
/// (VERIFIED/REJECTED/COMPLETED) tidak dianggap "aktif" lagi.
///
/// Aturan prioritas ini SATU-SATUNYA sumber kebenaran - jangan
/// duplikasi logika ini di controller/widget manapun.
/// ----------------------------------------------------------------------
class PickActiveTask {
  final GetActiveTasks _getActiveTasks;

  PickActiveTask(this._getActiveTasks);

  static const List<TaskStatusEntity> priorityOrder = [
    TaskStatusEntity.ongoing,
    TaskStatusEntity.revisionNeeded,
    TaskStatusEntity.draft,
    TaskStatusEntity.pendingVerification,
  ];

  Future<Either<Failure, TaskEntity?>> call() async {
    final result = await _getActiveTasks();
    return result.map(_pick);
  }

  TaskEntity? _pick(List<TaskEntity> tasks) {
    for (final status in priorityOrder) {
      final matches = tasks.where((t) => t.status == status).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (matches.isNotEmpty) return matches.first;
    }
    return null;
  }
}
