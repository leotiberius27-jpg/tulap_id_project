import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/camera_preferences_entity.dart';
import '../../domain/repositories/camera_preferences_repository.dart';

/// CameraPreferencesRepositoryImpl
/// ----------------------------------------------------------------------
/// Implementasi penyimpanan preferensi kamera menggunakan FlutterSecureStorage.
/// ----------------------------------------------------------------------
class CameraPreferencesRepositoryImpl implements CameraPreferencesRepository {
  static const String _kStorageKey = 'tulap_camera_preferences_v1';
  final FlutterSecureStorage _secureStorage;

  CameraPreferencesRepositoryImpl({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<CameraPreferencesEntity> getPreferences() async {
    try {
      final jsonStr = await _secureStorage.read(key: _kStorageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return const CameraPreferencesEntity();
      }
      return CameraPreferencesEntity.fromJson(jsonStr);
    } catch (_) {
      return const CameraPreferencesEntity();
    }
  }

  @override
  Future<void> savePreferences(CameraPreferencesEntity preferences) async {
    try {
      await _secureStorage.write(
        key: _kStorageKey,
        value: preferences.toJson(),
      );
    } catch (_) {}
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      await _secureStorage.delete(key: _kStorageKey);
    } catch (_) {}
  }
}
