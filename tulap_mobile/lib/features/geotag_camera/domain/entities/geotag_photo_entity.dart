/// GeotagPhotoEntity
/// ----------------------------------------------------------------------
/// Representasi murni "foto bukti kegiatan" di layer domain. Entity ini
/// TIDAK tahu apa-apa tentang file system, kamera, atau format JSON -
/// itu tanggung jawab layer data (lihat GeotagPhotoModel).
///
/// Field-field ini selaras dengan tabel `Geotag_Photo` di skema Prisma
/// backend, agar mapping data mobile -> API tidak membingungkan.
/// ----------------------------------------------------------------------
class GeotagPhotoEntity {
  final String id; // UUID lokal (dibuat di mobile sebelum sync ke server)
  final String taskId;
  final String localFilePath; // Path file di penyimpanan lokal perangkat

  final double latitude;
  final double longitude;
  final String? address; // Hasil reverse-geocoding, bisa null jika gagal
  final double gpsAccuracyMeters;
  final String plusCode; // Open Location Code - selalu tersedia (murni matematis, tidak butuh jaringan)

  final DateTime serverTimestamp; // Wajib dari server, bukan jam device
  final String integrityHash; // SHA-256 dari file foto mentah

  final bool isMockLocationDetected;
  final bool isRootedDeviceDetected;

  final String? caption;

  const GeotagPhotoEntity({
    required this.id,
    required this.taskId,
    required this.localFilePath,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyMeters,
    required this.plusCode,
    required this.serverTimestamp,
    required this.integrityHash,
    required this.isMockLocationDetected,
    required this.isRootedDeviceDetected,
    this.address,
    this.caption,
  });

  /// Sebuah foto dianggap layak dipakai sebagai bukti resmi hanya jika
  /// TIDAK ada indikasi mock location maupun perangkat compromised.
  bool get isEligibleAsOfficialEvidence =>
      !isMockLocationDetected && !isRootedDeviceDetected;
}
