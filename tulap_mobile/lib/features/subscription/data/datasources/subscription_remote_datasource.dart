import '../../../../core/network/dio_client.dart';

/// SubscriptionRemoteDataSource
/// ----------------------------------------------------------------------
/// GET /subscriptions/me adalah SUMBER KEBENARAN status langganan &
/// kuota - backend yang menegakkan (Bagian 24 instruksi payment),
/// mobile hanya membaca & menampilkan. SubscriptionLocalDataSource tetap
/// dipakai sebagai cache offline (lihat SubscriptionRepositoryImpl).
/// ----------------------------------------------------------------------
class SubscriptionRemoteDataSource {
  final DioClient _dioClient;
  SubscriptionRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getMySubscription() async {
    final response = await _dioClient.dio.get('/subscriptions/me');
    return response.data as Map<String, dynamic>;
  }

  /// POST /subscriptions/select-free (Bagian 41 - paket Gratis TIDAK
  /// melalui checkout QRIS/VA).
  Future<Map<String, dynamic>> selectFreePlan() async {
    final response = await _dioClient.dio.post('/subscriptions/select-free');
    return response.data as Map<String, dynamic>;
  }
}
