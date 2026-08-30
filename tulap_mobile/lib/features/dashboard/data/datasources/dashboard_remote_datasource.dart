import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_period.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getDashboardAnalytics(DashboardPeriod period);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient client;

  DashboardRemoteDataSourceImpl({required this.client});

  @override
  Future<DashboardSummaryModel> getDashboardAnalytics(DashboardPeriod period) async {
    final queryParams = <String, dynamic>{
      'period': period.type.name,
      'dateFrom': period.startDate.toIso8601String(),
      'dateTo': period.endDate.toIso8601String(),
    };

    final response = await client.dio.get(
      '/dashboard',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return DashboardSummaryModel.fromJson(data, period);
    }

    throw Exception('Gagal memuat analitik dashboard dari server');
  }
}
