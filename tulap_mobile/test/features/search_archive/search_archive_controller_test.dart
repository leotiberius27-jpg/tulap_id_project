import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_result_entity.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/recent_search_entity.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_filter_state.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/unified_search.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/get_recent_searches.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/save_recent_search.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/clear_recent_searches.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/rebuild_search_index.dart';
import 'package:tulap_mobile/features/search_archive/domain/usecases/get_available_years.dart';
import 'package:tulap_mobile/features/search_archive/presentation/controllers/search_archive_controller.dart';
import 'package:tulap_mobile/features/search_archive/domain/repositories/search_archive_repository.dart';

class FakeSearchArchiveRepository implements SearchArchiveRepository {
  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
    bool forceOffline = false,
  }) async {
    return Right([
      SearchResultEntity(
        entityId: 'act_101',
        entityType: SearchEntityType.activity,
        title: 'Inspeksi Jembatan Mimika',
        date: DateTime(2026, 8, 26),
        location: 'Kabupaten Mimika',
        relevanceScore: 90,
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches({int limit = 10}) async {
    return Right([
      RecentSearchEntity(
        id: '1',
        query: 'monitoring kendaraan',
        searchedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Either<Failure, void>> saveRecentSearch(String query) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeRecentSearch(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> backfillSearchIndex() async {
    return const Right(10);
  }

  @override
  Future<Either<Failure, void>> rebuildSearchIndex() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<int>>> getAvailableYears() async {
    return const Right([2026, 2025]);
  }
}

void main() {
  late SearchArchiveController controller;
  late FakeSearchArchiveRepository repository;

  setUp(() {
    repository = FakeSearchArchiveRepository();
    controller = SearchArchiveController(
      unifiedSearch: UnifiedSearch(repository),
      getRecentSearches: GetRecentSearches(repository),
      saveRecentSearch: SaveRecentSearch(repository),
      clearRecentSearches: ClearRecentSearches(repository),
      rebuildSearchIndex: RebuildSearchIndex(repository),
      getAvailableYears: GetAvailableYears(repository),
    );
  });

  group('SearchArchiveController Tests', () {
    test('initial state should be properly initialized and fetch archive items', () async {
      await controller.initialize();
      expect(controller.isInitialLoaded, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.results.length, 1);
      expect(controller.results.first.title, 'Inspeksi Jembatan Mimika');
      expect(controller.recentSearches.length, 1);
      expect(controller.availableYears, [2026, 2025]);
    });

    test('should update query and filter results', () async {
      await controller.initialize();
      controller.onQueryChanged('Mimika');
      expect(controller.query, 'Mimika');
    });

    test('should clear query properly', () async {
      await controller.initialize();
      controller.onQueryChanged('Jayapura');
      controller.clearQuery();
      expect(controller.query, '');
    });
  });
}
