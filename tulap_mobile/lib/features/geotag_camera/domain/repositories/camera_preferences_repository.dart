import '../entities/camera_preferences_entity.dart';

/// CameraPreferencesRepository
/// ----------------------------------------------------------------------
/// Kontrak persistensi preferensi & konfigurasi kamera lanjutan.
/// ----------------------------------------------------------------------
abstract class CameraPreferencesRepository {
  /// Mengambil preferensi kamera yang tersimpan, atau nilai default jika belum ada.
  Future<CameraPreferencesEntity> getPreferences();

  /// Menyimpan preferensi kamera.
  Future<void> savePreferences(CameraPreferencesEntity preferences);

  /// Mereset preferensi kamera kembali ke nilai default bawaan Tulap.id.
  Future<void> resetToDefaults();
}
