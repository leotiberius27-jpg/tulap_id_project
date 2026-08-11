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
    super.message = 'Gagal menyimpan foto ke perangkat.',
  ]);
}
