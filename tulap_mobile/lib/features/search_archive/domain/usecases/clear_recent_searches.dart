import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_archive_repository.dart';

class ClearRecentSearches {
  final SearchArchiveRepository repository;

  ClearRecentSearches(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.clearRecentSearches();
  }

  Future<Either<Failure, void>> remove(String id) {
    return repository.removeRecentSearch(id);
  }
}
