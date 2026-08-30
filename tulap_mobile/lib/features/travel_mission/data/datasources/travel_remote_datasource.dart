import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/lpj_package_model.dart';
import '../models/supporting_document_model.dart';
import '../models/travel_mission_model.dart';

class TravelRemoteDatasource {
  final DioClient _dioClient;

  TravelRemoteDatasource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<TravelMissionModel> createTravelMission(TravelMissionModel model) async {
    final response = await _dioClient.dio.post(
      '/travel',
      data: model.toApiPayload(),
    );
    return TravelMissionModel.fromJson(response.data);
  }

  Future<List<TravelMissionModel>> getTravelMissions({
    String? search,
    String? status,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (year != null) queryParams['year'] = year;

    final response = await _dioClient.dio.get(
      '/travel',
      queryParameters: queryParams,
    );

    final list = response.data as List;
    return list.map((e) => TravelMissionModel.fromJson(e)).toList();
  }

  Future<TravelMissionModel> getTravelMissionDetail(String id) async {
    final response = await _dioClient.dio.get('/travel/$id');
    return TravelMissionModel.fromJson(response.data);
  }

  Future<TravelMissionModel> updateTravelMission(
    String id,
    Map<String, dynamic> updatePayload,
  ) async {
    final response = await _dioClient.dio.patch('/travel/$id', data: updatePayload);
    return TravelMissionModel.fromJson(response.data);
  }

  Future<SupportingDocumentModel> uploadSupportingDocument(
    SupportingDocumentModel doc,
  ) async {
    final file = File(doc.filePath);
    final fileName = doc.filePath.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      ...doc.toApiPayload(),
      if (file.existsSync())
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
    });

    final response = await _dioClient.dio.post(
      '/travel/document',
      data: formData,
    );

    return SupportingDocumentModel.fromJson(response.data);
  }

  Future<LpjPackageModel> uploadLpjPackage(LpjPackageModel pkg) async {
    MultipartFile? pdfMultipart;
    if (pkg.pdfLocalPath != null && File(pkg.pdfLocalPath!).existsSync()) {
      final fileName = pkg.pdfLocalPath!.split(Platform.pathSeparator).last;
      pdfMultipart = await MultipartFile.fromFile(
        pkg.pdfLocalPath!,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap({
      ...pkg.toApiPayload(),
      if (pdfMultipart != null) 'file': pdfMultipart,
    });

    final response = await _dioClient.dio.post(
      '/travel/lpj',
      data: formData,
    );

    return LpjPackageModel.fromJson(response.data);
  }
}
