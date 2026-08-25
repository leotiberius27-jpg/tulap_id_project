import '../entities/account_settings_entity.dart';
import '../repositories/account_repository.dart';

class GetAccountSettings {
  final AccountRepository _repository;

  GetAccountSettings(this._repository);

  Future<CameraSettingsEntity> getCameraSettings() {
    return _repository.getCameraSettings();
  }

  Future<NotificationSettingsEntity> getNotificationSettings() {
    return _repository.getNotificationSettings();
  }
}
