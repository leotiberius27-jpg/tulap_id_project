import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/search_archive/data/services/search_result_merger.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_result_entity.dart';
import 'package:tulap_mobile/features/search_archive/domain/entities/search_filter_state.dart';

void main() {
  late SearchResultMerger merger;

  setUp(() {
    merger = SearchResultMerger();
  });

  group('SearchResultMerger Tests', () {
    test('should deduplicate records present in both local and remote', () {
      final local = [
        SearchResultEntity(
          entityId: 'act_1',
          entityType: SearchEntityType.activity,
          title: 'Monitoring Kendaraan',
          date: DateTime(2026, 8, 26),
          syncStatus: 'LOCAL_ONLY',
          relevanceScore: 50,
        ),
      ];

      final remote = [
        SearchResultEntity(
          entityId: 'act_1',
          entityType: SearchEntityType.activity,
          title: 'Monitoring Kendaraan Dinas',
          date: DateTime(2026, 8, 26),
          syncStatus: 'SYNCED',
          thumbnailUrl: 'https://cdn.tulap.id/photo1.jpg',
          relevanceScore: 90,
        ),
      ];

      final merged = merger.mergeAndRank(
        localResults: local,
        remoteResults: remote,
        sortOrder: SearchSortOrder.relevance,
      );

      expect(merged.length, 1);
      expect(merged.first.title, 'Monitoring Kendaraan Dinas');
      expect(merged.first.syncStatus, 'SYNCED');
      expect(merged.first.relevanceScore, 90);
    });

    test('should rank higher relevance scores at the top when sorting by relevance', () {
      final items = [
        SearchResultEntity(
          entityId: 'act_weak',
          entityType: SearchEntityType.activity,
          title: 'Rapat Koordinasi',
          date: DateTime(2026, 8, 28),
          relevanceScore: 20,
        ),
        SearchResultEntity(
          entityId: 'act_exact',
          entityType: SearchEntityType.activity,
          title: 'Monitoring Kendaraan Dinas',
          date: DateTime(2026, 8, 20),
          relevanceScore: 100,
        ),
      ];

      final merged = merger.mergeAndRank(
        localResults: items,
        remoteResults: const [],
        sortOrder: SearchSortOrder.relevance,
      );

      expect(merged.first.entityId, 'act_exact');
    });

    test('should sort by newest date when sorting by newest', () {
      final items = [
        SearchResultEntity(
          entityId: 'older',
          entityType: SearchEntityType.activity,
          title: 'Tugas Lama',
          date: DateTime(2026, 8, 10),
          relevanceScore: 90,
        ),
        SearchResultEntity(
          entityId: 'newer',
          entityType: SearchEntityType.activity,
          title: 'Tugas Baru',
          date: DateTime(2026, 8, 28),
          relevanceScore: 40,
        ),
      ];

      final merged = merger.mergeAndRank(
        localResults: items,
        remoteResults: const [],
        sortOrder: SearchSortOrder.newest,
      );

      expect(merged.first.entityId, 'newer');
    });
  });
}
