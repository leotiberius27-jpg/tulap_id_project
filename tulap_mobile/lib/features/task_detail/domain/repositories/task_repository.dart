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

  /// Mengambil daftar ringkas tugas milik user yang login, dipakai
  /// Beranda untuk menentukan "Kartu Tugas Aktif" (Bagian 11.1
  /// spesifikasi). BEDA dengan getTaskDetail: endpoint list backend
  /// (`GET /tasks`) tidak menyertakan checklist/jumlah bukti, jadi
  /// item di sini punya `checklistItems` kosong - caller yang butuh
  /// detail lengkap tetap harus memanggil getTaskDetail(id) terpisah.
  /// TIDAK memakai cache lokal (network-only) karena belum ada tabel
  /// cache untuk daftar tugas, hanya untuk satu tugas terakhir dibuka.
  Future<Either<Failure, List<TaskEntity>>> getActiveTasks();
}
