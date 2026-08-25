import '../entities/account_settings_entity.dart';
import '../repositories/account_repository.dart';

class SaveNotificationSettings {
  final AccountRepository _repository;

  SaveNotificationSettings(this._repository);

  Future<void> call(NotificationSettingsEntity settings) {
    return _repository.saveNotificationSettings(settings);
  }
}
