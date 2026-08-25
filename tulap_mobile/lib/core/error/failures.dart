/// Failure
/// ----------------------------------------------------------------------
/// Representasi error di layer domain/presentation. Berbeda dengan
/// Exception (dilempar di layer data saat error teknis terjadi),
/// Failure adalah objek yang DIKEMBALIKAN sebagai nilai (bukan
/// dilempar), sesuai pola Either<Failure, T> yang umum di Clean
/// Architecture Flutter.
/// ----------------------------------------------------------------------
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Gagal pada autentikasi
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal.']);
}

/// Gagal memuat tugas
class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure([super.message = 'Tugas tidak ditemukan.']);
}

/// Gagal submit verifikasi tugas karena checklist belum lengkap
class TaskSubmitRejectedFailure extends Failure {
  final List<String> incompleteItems;
  const TaskSubmitRejectedFailure(
    this.incompleteItems, [
    super.message = 'Checklist wajib belum lengkap.',
  ]);
}

/// Gagal koneksi server
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server.']);
}

/// Gagal karena lokasi perangkat tidak valid (mock location/GPS lemah)
class LocationInvalidFailure extends Failure {
  const LocationInvalidFailure([
    super.message = 'Lokasi perangkat tidak valid.',
  ]);
}

/// Gagal karena perangkat terindikasi root/jailbreak
class DeviceIntegrityFailure extends Failure {
  const DeviceIntegrityFailure([
    super.message = 'Perangkat tidak memenuhi syarat keamanan.',
  ]);
}

/// Gagal saat proses kamera (izin ditolak, hardware error, dsb)
class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Kamera tidak dapat diakses.']);
}

/// Gagal menyimpan foto ke penyimpanan lokal
class LocalStorageFailure extends Failure {
  const LocalStorageFailure([
    super.message = 'Gagal menyimpan data ke perangkat.',
  ]);
}

/// Gagal pada operasi database lokal SQLite
class DatabaseFailure extends Failure {
  const DatabaseFailure([
    super.message = 'Terjadi kesalahan pada database lokal.',
  ]);
}

/// Gagal validasi input
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Input data tidak valid.',
  ]);
}

