import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/payment_method_type.dart';
import '../../domain/entities/plan_code.dart';

/// PaymentsRemoteDataSource
/// ----------------------------------------------------------------------
/// Satu-satunya jalur mobile berbicara ke backend pembayaran. TIDAK
/// PERNAH memanggil payment provider (Midtrans) langsung dari mobile -
/// backend yang membuat transaksi & menentukan harga (Bagian 8 & 31
/// instruksi payment - "Server Menentukan Harga", "frontend -> backend
/// -> provider, BUKAN frontend -> provider").
/// ----------------------------------------------------------------------
class PaymentsRemoteDataSource {
  final DioClient _dioClient;
  PaymentsRemoteDataSource(this._dioClient);

  /// POST /payments/checkout - SENGAJA tidak punya parameter `amount`.
  /// `checkoutAttemptId` WAJIB diisi dari CheckoutController (UUID sekali
  /// per tap "Lanjutkan Pembayaran", dipakai ulang saat retry) - mencegah
  /// double-tap membuat dua transaksi provider (Bagian 32).
  Future<Map<String, dynamic>> checkout({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  }) async {
    final response = await _dioClient.dio.post(
      '/payments/checkout',
      data: {
        'planCode': planCode.apiValue,
        'billingCycle': billingCycle.apiValue,
        'paymentMethod': paymentMethod.apiValue,
        'checkoutAttemptId': checkoutAttemptId,
        if (vaBank != null) 'vaBank': vaBank,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getHistory() async {
    final response = await _dioClient.dio.get('/payments');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDetail(String publicReference) async {
    final response = await _dioClient.dio.get('/payments/$publicReference');
    return response.data as Map<String, dynamic>;
  }

  /// POST /payments/:publicReference/check-status - "Cek Status
  /// Pembayaran" (Bagian 13, 26, 31). Backend yang bertanya ke provider,
  /// mobile TIDAK PERNAH memanggil Midtrans langsung.
  Future<Map<String, dynamic>> checkStatus(String publicReference) async {
    final response = await _dioClient.dio.post('/payments/$publicReference/check-status');
    return response.data as Map<String, dynamic>;
  }
}

/// Helper bersama untuk mengekstrak pesan error dari response backend
/// (class-validator mengembalikan `message` sebagai String ATAU sebagai
/// daftar string) - dipakai repository payment & subscription.
String extractApiErrorMessage(Object error, String fallback) {
  if (error is DioException && error.response?.data is Map) {
    final data = error.response!.data as Map;
    final message = data['message'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
  }
  return fallback;
}
