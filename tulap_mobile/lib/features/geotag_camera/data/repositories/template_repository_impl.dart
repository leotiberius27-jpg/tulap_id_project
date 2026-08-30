import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/watermark_template_entity.dart';
import '../../domain/repositories/template_repository.dart';

/// TemplateRepositoryImpl
/// ----------------------------------------------------------------------
/// Implementasi persistensi konfigurasi template stamp menggunakan
/// FlutterSecureStorage / local key-value store.
/// ----------------------------------------------------------------------
class TemplateRepositoryImpl implements TemplateRepository {
  static const String _kTemplateConfigKey = 'tulap_stamp_configuration';

  final FlutterSecureStorage _storage;

  TemplateRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<StampConfiguration> getSavedConfiguration() async {
    try {
      final raw = await _storage.read(key: _kTemplateConfigKey);
      if (raw == null) return const StampConfiguration();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StampConfiguration.fromJson(map);
    } catch (_) {
      return const StampConfiguration();
    }
  }

  @override
  Future<void> saveConfiguration(StampConfiguration config) async {
    try {
      final raw = jsonEncode(config.toJson());
      await _storage.write(key: _kTemplateConfigKey, value: raw);
    } catch (_) {}
  }
}
