import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/search_result_entity.dart';
import '../entities/search_filter_state.dart';
import '../repositories/search_archive_repository.dart';

class UnifiedSearchParams {
  final String query;
  final SearchFilterState filter;
  final String? cursor;
  final int limit;
  final bool forceOffline;

  const UnifiedSearchParams({
    required this.query,
    required this.filter,
    this.cursor,
    this.limit = 20,
    this.forceOffline = false,
  });
}

class UnifiedSearch {
  final SearchArchiveRepository repository;

  UnifiedSearch(this.repository);

  Future<Either<Failure, List<SearchResultEntity>>> call(UnifiedSearchParams params) {
    return repository.search(
      query: params.query,
      filter: params.filter,
      cursor: params.cursor,
      limit: params.limit,
      forceOffline: params.forceOffline,
    );
  }
}
