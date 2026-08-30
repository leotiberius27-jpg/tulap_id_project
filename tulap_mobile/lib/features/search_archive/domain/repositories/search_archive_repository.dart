import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/search_result_entity.dart';
import '../entities/search_filter_state.dart';
import '../entities/recent_search_entity.dart';

abstract class SearchArchiveRepository {
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  });

  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10});

  Future<Either<Failure, void>> saveRecentSearch(String query);

  Future<Either<Failure, void>> removeRecentSearch(String id);

  Future<Either<Failure, void>> clearRecentSearches();

  Future<Either<Failure, int>> backfillSearchIndex();

  Future<Either<Failure, void>> rebuildSearchIndex();

  Future<Either<Failure, List<int>>> getAvailableYears();
}
