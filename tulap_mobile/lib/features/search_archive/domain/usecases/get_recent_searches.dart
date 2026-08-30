import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/recent_search_entity.dart';
import '../repositories/search_archive_repository.dart';

class GetRecentSearches {
  final SearchArchiveRepository repository;

  GetRecentSearches(this.repository);

  Future<Either<Failure, List<RecentSearchEntity>>> call({int limit = 10}) {
    return repository.getRecentSearches(limit: limit);
  }
}
