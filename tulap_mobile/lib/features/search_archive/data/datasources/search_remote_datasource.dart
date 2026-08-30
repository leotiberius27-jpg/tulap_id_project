import '../../../../core/network/dio_client.dart';
import '../../domain/entities/search_filter_state.dart';
import '../../domain/entities/search_query_parsed.dart';
import '../models/search_result_model.dart';

abstract class SearchRemoteDatasource {
  Future<List<SearchResultModel>> searchRemote({
    required SearchQueryParsed parsedQuery,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
  });
}

class SearchRemoteDatasourceImpl implements SearchRemoteDatasource {
  final DioClient client;

  SearchRemoteDatasourceImpl({required this.client});

  @override
  Future<List<SearchResultModel>> searchRemote({
    required SearchQueryParsed parsedQuery,
    required SearchFilterState filter,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };

    if (parsedQuery.rawQuery.trim().isNotEmpty) {
      queryParams['q'] = parsedQuery.rawQuery.trim();
    }

    final type = filter.selectedType ?? parsedQuery.detectedType;
    if (type != null) {
      queryParams['entityTypes'] = type.name.toUpperCase();
    }

    if (filter.startDate != null) {
      queryParams['dateFrom'] = filter.startDate!.toIso8601String();
    }
    if (filter.endDate != null) {
      queryParams['dateTo'] = filter.endDate!.toIso8601String();
    }
    if (filter.selectedYear != null || parsedQuery.detectedYear != null) {
      queryParams['year'] = filter.selectedYear ?? parsedQuery.detectedYear!;
    }
    if (filter.location != null && filter.location!.isNotEmpty) {
      queryParams['location'] = filter.location;
    }
    if (filter.status != null && filter.status!.isNotEmpty) {
      queryParams['status'] = filter.status;
    }
    if (filter.expenseCategory != null && filter.expenseCategory!.isNotEmpty) {
      queryParams['category'] = filter.expenseCategory;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    switch (filter.sortOrder) {
      case SearchSortOrder.newest:
        queryParams['sort'] = 'newest';
        break;
      case SearchSortOrder.oldest:
        queryParams['sort'] = 'oldest';
        break;
      case SearchSortOrder.relevance:
        queryParams['sort'] = 'relevance';
        break;
    }

    try {
      final response = await client.dio.get('/search', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final items = (data['items'] as List<dynamic>? ?? [])
            .map((item) => SearchResultModel.fromRemoteJson(item as Map<String, dynamic>))
            .toList();
        return items;
      }
      return const [];
    } catch (_) {
      // Graceful fallback when remote search is unreachable or offline
      return const [];
    }
  }
}
