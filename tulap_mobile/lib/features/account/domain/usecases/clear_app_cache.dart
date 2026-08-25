import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/account_repository.dart';

class ClearAppCache {
  final AccountRepository _repository;

  ClearAppCache(this._repository);

  Future<Either<Failure, int>> call() {
    return _repository.clearTemporaryCache();
  }
}
