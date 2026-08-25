import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_settings_entity.dart';
import '../../domain/entities/storage_breakdown_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountLocalDataSource _localDataSource;

  AccountRepositoryImpl({required AccountLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<CameraSettingsEntity> getCameraSettings() {
    return _localDataSource.getCameraSettings();
  }

  @override
  Future<void> saveCameraSettings(CameraSettingsEntity settings) {
    return _localDataSource.saveCameraSettings(settings);
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() {
    return _localDataSource.getNotificationSettings();
  }

  @override
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings) {
    return _localDataSource.saveNotificationSettings(settings);
  }

  @override
  Future<StorageBreakdownEntity> getStorageBreakdown() {
    return _localDataSource.getStorageBreakdown();
  }

  @override
  Future<Either<Failure, int>> clearTemporaryCache() async {
    try {
      final bytesCleared = await _localDataSource.clearTemporaryCache();
      return Right(bytesCleared);
    } catch (e) {
      return Left(LocalStorageFailure('Gagal membersihkan cache: ${e.toString()}'));
    }
  }
}
