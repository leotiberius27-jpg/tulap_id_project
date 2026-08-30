import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_theme_mode.dart';
import '../../domain/entities/account_settings_entity.dart';
import '../../domain/entities/storage_breakdown_entity.dart';

abstract class AccountLocalDataSource {
  Future<CameraSettingsEntity> getCameraSettings();
  Future<void> saveCameraSettings(CameraSettingsEntity settings);
  Future<NotificationSettingsEntity> getNotificationSettings();
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings);
  Future<AppThemeMode> getThemeMode();
  Future<void> saveThemeMode(AppThemeMode mode);
  Future<AppLanguage> getLanguage();
  Future<void> saveLanguage(AppLanguage language);
  Future<StorageBreakdownEntity> getStorageBreakdown();
  Future<int> clearTemporaryCache();
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  static const String _kCameraSettingsKey = 'settings_camera_watermark';
  static const String _kNotificationSettingsKey = 'settings_notifications';
  static const String _kThemeModeKey = 'settings_app_theme_mode';
  static const String _kLanguageKey = 'settings_app_language';

  final FlutterSecureStorage _secureStorage;
  final Database? _database;

  AccountLocalDataSourceImpl({
    FlutterSecureStorage? secureStorage,
    Database? database,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _database = database;

  @override
  Future<CameraSettingsEntity> getCameraSettings() async {
    try {
      final raw = await _secureStorage.read(key: _kCameraSettingsKey);
      if (raw == null) return const CameraSettingsEntity();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CameraSettingsEntity.fromJson(map);
    } catch (_) {
      return const CameraSettingsEntity();
    }
  }

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) async {
    await _secureStorage.write(
      key: _kCameraSettingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    try {
      final raw = await _secureStorage.read(key: _kNotificationSettingsKey);
      if (raw == null) return const NotificationSettingsEntity();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationSettingsEntity.fromJson(map);
    } catch (_) {
      return const NotificationSettingsEntity();
    }
  }

  @override
  Future<void> saveNotificationSettings(
    NotificationSettingsEntity settings,
  ) async {
    await _secureStorage.write(
      key: _kNotificationSettingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }

  @override
  Future<AppThemeMode> getThemeMode() async {
    try {
      final raw = await _secureStorage.read(key: _kThemeModeKey);
      if (raw == null) return AppThemeMode.light;
      return AppThemeMode.fromCode(raw);
    } catch (_) {
      return AppThemeMode.light;
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      await _secureStorage.write(
        key: _kThemeModeKey,
        value: mode.toCode(),
      );
    } catch (_) {}
  }

  @override
  Future<AppLanguage> getLanguage() async {
    try {
      final raw = await _secureStorage.read(key: _kLanguageKey);
      if (raw == null) return AppLanguage.id;
      return AppLanguage.fromCode(raw);
    } catch (_) {
      return AppLanguage.id;
    }
  }

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    try {
      await _secureStorage.write(
        key: _kLanguageKey,
        value: language.code,
      );
    } catch (_) {}
  }

  @override
  Future<StorageBreakdownEntity> getStorageBreakdown() async {
    int cacheBytes = 0;
    int photosBytes = 0;
    int dbBytes = 0;
    int pendingCount = 0;

    try {
      // 1. Temporary Cache Size
      final tempDir = await getTemporaryDirectory();
      cacheBytes = await _calculateDirectorySize(tempDir);
    } catch (_) {}

    try {
      // 2. Photos & Documents Size
      final appDocDir = await getApplicationDocumentsDirectory();
      photosBytes = await _calculateDirectorySize(appDocDir);
    } catch (_) {}

    try {
      // 3. Database Size
      final dbPath = await getDatabasesPath();
      final dbDir = Directory(dbPath);
      dbBytes = await _calculateDirectorySize(dbDir);
    } catch (_) {}

    try {
      // 4. Pending uploads count from SQLite
      if (_database != null) {
        final countResult = await _database.rawQuery(
          "SELECT COUNT(*) as count FROM sync_queue WHERE status IN ('pendingUpload', 'waitingForInternet', 'uploading')",
        );
        if (countResult.isNotEmpty) {
          pendingCount = (countResult.first['count'] as int?) ?? 0;
        }
      }
    } catch (_) {}

    final total = cacheBytes + photosBytes + dbBytes;

    return StorageBreakdownEntity(
      databaseBytes: dbBytes,
      photosBytes: photosBytes,
      cacheBytes: cacheBytes,
      pendingUploadsCount: pendingCount,
      totalBytes: total,
    );
  }

  @override
  Future<int> clearTemporaryCache() async {
    int deletedBytes = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        deletedBytes = await _calculateDirectorySize(tempDir);
        final entities = tempDir.listSync(
          recursive: false,
          followLinks: false,
        );
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return deletedBytes;
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int totalSize = 0;
    try {
      final List<FileSystemEntity> entities = dir.listSync(
        recursive: true,
        followLinks: false,
      );
      for (final entity in entities) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return totalSize;
  }
}
