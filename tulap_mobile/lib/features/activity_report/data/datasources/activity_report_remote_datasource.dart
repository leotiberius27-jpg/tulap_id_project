import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/activity_report_model.dart';

abstract class ActivityReportRemoteDataSource {
  Future<List<ActivityReportModel>> getTaskReports(String taskId);
  Future<ActivityReportModel?> getReportById(String reportId);
  Future<void> deleteReport(String reportId);
  Future<File> downloadReportPdf(String remoteUrl, String localSavePath);
}

class ActivityReportRemoteDataSourceImpl implements ActivityReportRemoteDataSource {
  final DioClient _dioClient;

  ActivityReportRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<ActivityReportModel>> getTaskReports(String taskId) async {
    try {
      final response = await _dioClient.dio.get('/lpj/report/task/$taskId');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => ActivityReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ActivityReportModel?> getReportById(String reportId) async {
    try {
      final response = await _dioClient.dio.get('/lpj/report/$reportId');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return ActivityReportModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await _dioClient.dio.delete('/lpj/report/$reportId');
  }

  @override
  Future<File> downloadReportPdf(String remoteUrl, String localSavePath) async {
    final response = await _dioClient.dio.get(
      remoteUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final file = File(localSavePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.data as List<int>);
    return file;
  }
}
