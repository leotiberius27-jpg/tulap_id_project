import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/search_filter_state.dart';
import '../../domain/entities/search_query_parsed.dart';
import '../models/search_result_model.dart';
import '../models/recent_search_model.dart';

abstract class SearchLocalDatasource {
  Future<List<SearchResultModel>> searchLocal({
    required SearchQueryParsed parsedQuery,
    required SearchFilterState filter,
    int limit = 50,
  });

  Future<List<RecentSearchModel>> getRecentSearches({int limit = 10});

  Future<void> saveRecentSearch(String query);

  Future<void> removeRecentSearch(String id);

  Future<void> clearRecentSearches();

  Future<List<int>> getAvailableYears();
}

class SearchLocalDatasourceImpl implements SearchLocalDatasource {
  Future<Database> get _db => LocalDatabase.instance;

  @override
  Future<List<SearchResultModel>> searchLocal({
    required SearchQueryParsed parsedQuery,
    required SearchFilterState filter,
    int limit = 50,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // 1. Filter Entity Type
    final effectiveType = filter.selectedType ?? parsedQuery.detectedType;
    if (effectiveType != null) {
      whereClauses.add('entityType = ?');
      whereArgs.add(effectiveType.name.toUpperCase());
    }

    // 2. Filter Date / Year
    if (filter.startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(filter.startDate!.toIso8601String());
    }
    if (filter.endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(filter.endDate!.toIso8601String());
    }
    if (filter.selectedYear != null || parsedQuery.detectedYear != null) {
      final year = filter.selectedYear ?? parsedQuery.detectedYear!;
      whereClauses.add("date LIKE ?");
      whereArgs.add('$year%');
    }

    // 3. Filter Location
    final effectiveLoc = filter.location ?? parsedQuery.detectedLocation;
    if (effectiveLoc != null && effectiveLoc.isNotEmpty) {
      whereClauses.add('(location LIKE ? OR district LIKE ? OR city LIKE ? OR province LIKE ?)');
      final locPattern = '%$effectiveLoc%';
      whereArgs.addAll([locPattern, locPattern, locPattern, locPattern]);
    }

    // 4. Filter Status
    if (filter.status != null && filter.status!.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(filter.status);
    }

    // 5. Filter Category
    if (filter.expenseCategory != null && filter.expenseCategory!.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(filter.expenseCategory);
    }

    // 6. Text Match Condition
    if (parsedQuery.cleanText.isNotEmpty) {
      final textPattern = '%${parsedQuery.cleanText}%';
      whereClauses.add('(normalizedText LIKE ? OR searchableText LIKE ? OR entityId LIKE ?)');
      whereArgs.addAll([textPattern, textPattern, '%${parsedQuery.rawQuery.trim()}%']);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final rows = await db.query(
      'search_index',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
    );

    final results = <SearchResultModel>[];
    for (final row in rows) {
      final model = SearchResultModel.fromSqlite(row);
      final score = _calculateLocalScore(model, parsedQuery);
      results.add(
        SearchResultModel(
          entityId: model.entityId,
          entityType: model.entityType,
          title: model.title,
          subtitle: model.subtitle,
          date: model.date,
          location: model.location,
          district: model.district,
          city: model.city,
          province: model.province,
          localThumbnailPath: model.localThumbnailPath,
          syncStatus: model.syncStatus,
          relevanceScore: score,
          parentId: model.parentId,
          metadata: model.metadata,
        ),
      );
    }

    return results;
  }

  int _calculateLocalScore(SearchResultModel model, SearchQueryParsed query) {
    if (query.cleanText.isEmpty) return 10;
    final lowerTitle = model.title.toLowerCase();
    final lowerSub = (model.subtitle ?? '').toLowerCase();
    final clean = query.cleanText;

    // Exact ID
    if (query.isExactId && (model.entityId.toLowerCase() == clean || (model.metadata?['taskCode'] ?? '').toString().toLowerCase() == clean || (model.metadata?['displayId'] ?? '').toString().toLowerCase() == clean || (model.metadata?['packageCode'] ?? '').toString().toLowerCase() == clean)) {
      return 100;
    }

    // Exact Title
    if (lowerTitle == clean) return 90;

    // Title contains
    if (lowerTitle.contains(clean)) return 70;

    // Amount match
    if (query.detectedAmount != null) {
      final budget = double.tryParse((model.metadata?['budgetAmount'] ?? '').toString());
      final total = double.tryParse((model.metadata?['totalAmount'] ?? '').toString());
      if ((budget != null && (budget - query.detectedAmount!).abs() < 1) ||
          (total != null && (total - query.detectedAmount!).abs() < 1)) {
        return 85;
      }
    }

    // Subtitle contains
    if (lowerSub.contains(clean)) return 50;

    // OCR Raw match (secondary)
    final ocr = (model.metadata?['ocrRawText'] ?? '').toString().toLowerCase();
    if (ocr.contains(clean)) return 25;

    return 30;
  }

  @override
  Future<List<RecentSearchModel>> getRecentSearches({int limit = 10}) async {
    final db = await _db;
    final rows = await db.query(
      'recent_searches',
      orderBy: 'searchedAt DESC',
      limit: limit,
    );
    return rows.map((r) => RecentSearchModel.fromSqlite(r)).toList();
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final db = await _db;
    final id = 'search_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(
      'recent_searches',
      {
        'id': id,
        'query': trimmed,
        'searchedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeRecentSearch(String id) async {
    final db = await _db;
    await db.delete('recent_searches', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearRecentSearches() async {
    final db = await _db;
    await db.delete('recent_searches');
  }

  @override
  Future<List<int>> getAvailableYears() async {
    final db = await _db;
    try {
      final rows = await db.rawQuery(
        "SELECT DISTINCT SUBSTR(date, 1, 4) as year FROM search_index WHERE date IS NOT NULL AND length(date) >= 4 ORDER BY year DESC",
      );
      final years = <int>[];
      for (final r in rows) {
        final yStr = r['year'] as String?;
        if (yStr != null) {
          final y = int.tryParse(yStr);
          if (y != null && y >= 2000 && y <= 2100) {
            years.add(y);
          }
        }
      }
      if (years.isEmpty) {
        years.add(DateTime.now().year);
      }
      return years;
    } catch (_) {
      return [DateTime.now().year];
    }
  }
}
