import '../entities/watermark_template_entity.dart';

/// TemplateRepository
/// ----------------------------------------------------------------------
/// Kontrak repositori untuk menyimpan & membaca preferensi template stamp aktif.
/// ----------------------------------------------------------------------
abstract class TemplateRepository {
  Future<StampConfiguration> getSavedConfiguration();
  Future<void> saveConfiguration(StampConfiguration config);
}
