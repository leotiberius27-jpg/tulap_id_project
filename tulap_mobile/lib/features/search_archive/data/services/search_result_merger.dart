import '../../domain/entities/search_result_entity.dart';
import '../../domain/entities/search_filter_state.dart';

class SearchResultMerger {
  List<SearchResultEntity> mergeAndRank({
    required List<SearchResultEntity> localResults,
    required List<SearchResultEntity> remoteResults,
    required SearchSortOrder sortOrder,
  }) {
    final Map<String, SearchResultEntity> map = {};

    // 1. Masukkan hasil lokal terlebih dahulu
    for (final item in localResults) {
      map[item.uniqueKey] = item;
    }

    // 2. Gabungkan dengan hasil remote (Deduplikasi & Rekonsiliasi Authoritative)
    for (final remote in remoteResults) {
      final key = remote.uniqueKey;
      if (map.containsKey(key)) {
        final existingLocal = map[key]!;
        // Gabungkan: pertahankan thumbnail lokal jika ada, update thumbnail remote & syncStatus
        map[key] = SearchResultEntity(
          entityId: remote.entityId,
          entityType: remote.entityType,
          title: remote.title.isNotEmpty ? remote.title : existingLocal.title,
          subtitle: remote.subtitle ?? existingLocal.subtitle,
          date: remote.date,
          location: remote.location ?? existingLocal.location,
          district: remote.district ?? existingLocal.district,
          city: remote.city ?? existingLocal.city,
          province: remote.province ?? existingLocal.province,
          thumbnailUrl: remote.thumbnailUrl ?? existingLocal.thumbnailUrl,
          localThumbnailPath: existingLocal.localThumbnailPath,
          matchedField: remote.matchedField ?? existingLocal.matchedField,
          matchedSnippet: remote.matchedSnippet ?? existingLocal.matchedSnippet,
          relevanceScore: remote.relevanceScore > existingLocal.relevanceScore
              ? remote.relevanceScore
              : existingLocal.relevanceScore,
          syncStatus: 'SYNCED',
          parentId: remote.parentId ?? existingLocal.parentId,
          metadata: {
            ...?existingLocal.metadata,
            ...?remote.metadata,
          },
        );
      } else {
        map[key] = remote;
      }
    }

    final list = map.values.toList();

    // 3. Sorting & Ranking
    switch (sortOrder) {
      case SearchSortOrder.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SearchSortOrder.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SearchSortOrder.relevance:
        list.sort((a, b) {
          if (b.relevanceScore != a.relevanceScore) {
            return b.relevanceScore.compareTo(a.relevanceScore);
          }
          return b.date.compareTo(a.date);
        });
        break;
    }

    return list;
  }
}
