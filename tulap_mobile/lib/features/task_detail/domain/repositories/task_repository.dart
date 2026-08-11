import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

/// TaskRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class TaskRepository {
  /// Mengambil detail tugas + checklist-nya. Strategi offline-first:
  /// ambil dari cache lokal dulu (langsung tampil, tidak nunggu
  /// network), lalu refresh dari server di background jika online -
  /// lihat implementasi lengkap di TaskRepositoryImpl.
  Future<Either<Failure, TaskEntity>> getTaskDetail(String taskId);

  /// Toggle checklist SELALU berhasil secara lokal dulu (offline-first),
  /// perubahan didaftarkan ke Sync Queue untuk dikirim ke server -
  /// TIDAK menunggu response server sebelum UI update, sesuai prinsip
  /// "less waiting" di seluruh aplikasi Tulap.id.
  Future<Either<Failure, ChecklistItemEntity>> toggleChecklistItem({
    required String taskId,
    required String itemId,
    required bool isCompleted,
  });

  Future<Either<Failure, TaskEntity>> startTask(String taskId);

  /// Mengirim tugas untuk verifikasi. INI butuh koneksi online (tidak
  /// bisa dilakukan offline) karena backend perlu memvalidasi ulang
  /// kelengkapan checklist sebagai sumber kebenaran final - client
  /// hanya melakukan pre-check optimis lewat `TaskEntity.isReadyToSubmit`.
  Future<Either<Failure, TaskEntity>> submitForVerification(String taskId);
}
