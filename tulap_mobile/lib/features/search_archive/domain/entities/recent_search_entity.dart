class RecentSearchEntity {
  final String id;
  final String query;
  final DateTime searchedAt;

  const RecentSearchEntity({
    required this.id,
    required this.query,
    required this.searchedAt,
  });
}
