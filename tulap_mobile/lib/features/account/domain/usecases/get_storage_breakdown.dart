import '../entities/storage_breakdown_entity.dart';
import '../repositories/account_repository.dart';

class GetStorageBreakdown {
  final AccountRepository _repository;

  GetStorageBreakdown(this._repository);

  Future<StorageBreakdownEntity> call() {
    return _repository.getStorageBreakdown();
  }
}
