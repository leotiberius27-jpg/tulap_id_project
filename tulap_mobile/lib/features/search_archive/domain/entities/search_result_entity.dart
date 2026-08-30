enum SearchEntityType {
  activity('Kegiatan', 'ACT'),
  travel('Perjalanan', 'PD'),
  evidence('Dokumentasi', 'EV'),
  receipt('Nota', 'NTA'),
  expense('Pengeluaran', 'EXP'),
  report('Laporan', 'LAP'),
  document('Dokumen', 'DOC'),
  lpj('LPJ', 'LPJ');

  final String label;
  final String codePrefix;
  const SearchEntityType(this.label, this.codePrefix);

  static SearchEntityType fromString(String val) {
    final v = val.toUpperCase().trim();
    switch (v) {
      case 'ACTIVITY':
      case 'TASK':
        return SearchEntityType.activity;
      case 'TRAVEL':
      case 'TRAVEL_MISSION':
        return SearchEntityType.travel;
      case 'EVIDENCE':
      case 'PHOTO':
      case 'VIDEO':
        return SearchEntityType.evidence;
      case 'RECEIPT':
        return SearchEntityType.receipt;
      case 'EXPENSE':
        return SearchEntityType.expense;
      case 'REPORT':
        return SearchEntityType.report;
      case 'DOCUMENT':
      case 'SUPPORTING_DOCUMENT':
        return SearchEntityType.document;
      case 'LPJ':
      case 'LPJ_PACKAGE':
        return SearchEntityType.lpj;
      default:
        return SearchEntityType.activity;
    }
  }
}

class SearchResultEntity {
  final String entityId;
  final SearchEntityType entityType;
  final String title;
  final String? subtitle;
  final DateTime date;
  final String? location;
  final String? district;
  final String? city;
  final String? province;
  final String? thumbnailUrl;
  final String? localThumbnailPath;
  final String? matchedField;
  final String? matchedSnippet;
  final int relevanceScore;
  final String syncStatus;
  final String? parentId;
  final Map<String, dynamic>? metadata;

  const SearchResultEntity({
    required this.entityId,
    required this.entityType,
    required this.title,
    this.subtitle,
    required this.date,
    this.location,
    this.district,
    this.city,
    this.province,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.matchedField,
    this.matchedSnippet,
    this.relevanceScore = 0,
    this.syncStatus = 'SYNCED',
    this.parentId,
    this.metadata,
  });

  /// Unique deduplication key: entityType + entityId
  String get uniqueKey => '${entityType.name}_$entityId';
}
