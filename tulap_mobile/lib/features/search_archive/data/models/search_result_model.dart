import 'dart:convert';
import '../../domain/entities/search_result_entity.dart';

class SearchResultModel extends SearchResultEntity {
  const SearchResultModel({
    required super.entityId,
    required super.entityType,
    required super.title,
    super.subtitle,
    required super.date,
    super.location,
    super.district,
    super.city,
    super.province,
    super.thumbnailUrl,
    super.localThumbnailPath,
    super.matchedField,
    super.matchedSnippet,
    super.relevanceScore = 0,
    super.syncStatus = 'SYNCED',
    super.parentId,
    super.metadata,
  });

  factory SearchResultModel.fromSqlite(Map<String, dynamic> map) {
    Map<String, dynamic>? meta;
    if (map['metadataJson'] != null && map['metadataJson'].toString().isNotEmpty) {
      try {
        meta = jsonDecode(map['metadataJson'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return SearchResultModel(
      entityId: map['entityId'] as String,
      entityType: SearchEntityType.fromString(map['entityType'] as String),
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      location: map['location'] as String?,
      district: map['district'] as String?,
      city: map['city'] as String?,
      province: map['province'] as String?,
      localThumbnailPath: map['thumbnailPath'] as String?,
      syncStatus: map['syncStatus'] as String? ?? 'LOCAL_ONLY',
      parentId: map['parentId'] as String?,
      metadata: meta,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'entityId': entityId,
      'entityType': entityType.name.toUpperCase(),
      'title': title,
      'subtitle': subtitle,
      'searchableText': _buildSearchableText(),
      'normalizedText': _buildNormalizedText(),
      'date': date.toIso8601String(),
      'location': location,
      'district': district,
      'city': city,
      'province': province,
      'category': metadata?['category'] as String?,
      'status': metadata?['status'] as String?,
      'syncStatus': syncStatus,
      'thumbnailPath': localThumbnailPath,
      'parentId': parentId,
      'metadataJson': metadata != null ? jsonEncode(metadata) : null,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory SearchResultModel.fromRemoteJson(Map<String, dynamic> json) {
    return SearchResultModel(
      entityId: json['entityId'] as String,
      entityType: SearchEntityType.fromString(json['entityType'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      matchedField: json['matchedField'] as String?,
      matchedSnippet: json['matchedText'] as String?,
      relevanceScore: (json['relevanceScore'] as num?)?.toInt() ?? 0,
      syncStatus: json['syncStatus'] as String? ?? 'SYNCED',
      parentId: json['parentId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String _buildSearchableText() {
    final buffer = StringBuffer();
    buffer.write('$title ');
    if (subtitle != null) buffer.write('$subtitle ');
    if (location != null) buffer.write('$location ');
    if (district != null) buffer.write('$district ');
    if (city != null) buffer.write('$city ');
    if (province != null) buffer.write('$province ');
    if (metadata != null) {
      for (final val in metadata!.values) {
        if (val != null) buffer.write('$val ');
      }
    }
    return buffer.toString().trim();
  }

  String _buildNormalizedText() {
    return _buildSearchableText().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }
}
