import '../entities/account_settings_entity.dart';
import '../repositories/account_repository.dart';

class SaveCameraSettings {
  final AccountRepository _repository;

  SaveCameraSettings(this._repository);

  Future<void> call(CameraSettingsEntity settings) {
    return _repository.saveCameraSettings(settings);
  }
}
