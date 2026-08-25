import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_settings_entity.dart';
import '../entities/storage_breakdown_entity.dart';

/// AccountRepository (interface/kontrak)
/// ----------------------------------------------------------------------
/// Kontrak pengelolaan akun pengguna, preferensi pengaturan,
/// penyimpanan lokal, serta pembersihan cache yang aman.
/// ----------------------------------------------------------------------
abstract class AccountRepository {
  /// Mengambil preferensi watermark kamera
  Future<CameraSettingsEntity> getCameraSettings();

  /// Menyimpan preferensi watermark kamera
  Future<void> saveCameraSettings(CameraSettingsEntity settings);

  /// Mengambil preferensi notifikasi
  Future<NotificationSettingsEntity> getNotificationSettings();

  /// Menyimpan preferensi notifikasi
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings);

  /// Mengukur penggunaan ruang penyimpanan lokal (Database, Foto, Cache, Outbox)
  Future<StorageBreakdownEntity> getStorageBreakdown();

  /// Membersihkan cache sementara tanpa menghapus foto bukti atau database
  Future<Either<Failure, int>> clearTemporaryCache();
}
