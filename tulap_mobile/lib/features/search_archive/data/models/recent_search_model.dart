import '../../domain/entities/recent_search_entity.dart';

class RecentSearchModel extends RecentSearchEntity {
  const RecentSearchModel({
    required super.id,
    required super.query,
    required super.searchedAt,
  });

  factory RecentSearchModel.fromSqlite(Map<String, dynamic> map) {
    return RecentSearchModel(
      id: map['id'] as String,
      query: map['query'] as String,
      searchedAt: DateTime.tryParse(map['searchedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'query': query,
      'searchedAt': searchedAt.toIso8601String(),
    };
  }
}
