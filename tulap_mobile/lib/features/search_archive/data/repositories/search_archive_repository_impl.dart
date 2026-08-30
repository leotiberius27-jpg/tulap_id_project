import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/entities/search_filter_state.dart';
import '../../domain/entities/recent_search_entity.dart';
import '../../domain/repositories/search_archive_repository.dart';
import '../datasources/search_local_datasource.dart';
import '../datasources/search_remote_datasource.dart';
import '../services/search_query_parser.dart';
import '../services/search_result_merger.dart';
import '../services/search_index_service.dart';

class SearchArchiveRepositoryImpl implements SearchArchiveRepository {
  final SearchLocalDatasource localDatasource;
  final SearchRemoteDatasource remoteDatasource;
  final SearchQueryParser queryParser;
  final SearchResultMerger merger;
  final SearchIndexService indexService;
  final NetworkInfo networkInfo;

  SearchArchiveRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.queryParser,
    required this.merger,
    required this.indexService,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  }) async {
    try {
      final parsedQuery = queryParser.parse(query);

      // 1. Eksekusi pencarian lokal
      final localResults = await localDatasource.searchLocal(
        parsedQuery: parsedQuery,
        filter: filter,
        limit: limit * 2,
      );

      List<SearchResultEntity> remoteResults = const [];

      // 2. Eksekusi pencarian remote jika online dan tidak dipaksa offline
      if (!forceOffline) {
        final isConnected = await networkInfo.isConnected;
        if (isConnected) {
          try {
            remoteResults = await remoteDatasource.searchRemote(
              parsedQuery: parsedQuery,
              filter: filter,
              cursor: cursor,
              limit: limit,
            );
          } catch (_) {
            // Fallback transparan ke hasil lokal
          }
        }
      }

      // 3. Merger, Deduplikasi, dan Ranking
      final merged = merger.mergeAndRank(
        localResults: localResults,
        remoteResults: remoteResults,
        sortOrder: filter.sortOrder,
      );

      return Right(merged);
    } catch (e) {
      return Left(DatabaseFailure('Gagal melakukan pencarian arsip: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10}) async {
    try {
      final items = await localDatasource.getRecentSearches(limit: limit);
      return Right(items);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat riwayat pencarian: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveRecentSearch(String query) async {
    try {
      await localDatasource.saveRecentSearch(query);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan riwayat pencarian: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeRecentSearch(String id) async {
    try {
      await localDatasource.removeRecentSearch(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghapus item pencarian: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    try {
      await localDatasource.clearRecentSearches();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal membersihkan riwayat pencarian: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> backfillSearchIndex() async {
    try {
      final count = await indexService.backfillAll();
      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure('Gagal melakukan backfill indeks: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rebuildSearchIndex() async {
    try {
      await indexService.rebuildIndex();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal membangun ulang indeks: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> getAvailableYears() async {
    try {
      final years = await localDatasource.getAvailableYears();
      return Right(years);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memuat tahun arsip: $e'));
    }
  }
}
