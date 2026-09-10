import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/payment_method_type.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/usecases/create_checkout.dart';

enum CheckoutStatus { idle, submitting, success, error }

/// CheckoutController
/// ----------------------------------------------------------------------
/// Mengelola SATU sesi checkout (Ringkasan Pembayaran -> Pilih Metode ->
/// transaksi dibuat). `checkoutAttemptId` dibuat SEKALI PER METODE
/// pembayaran (Bagian 32 instruksi payment - "Prevent Double Payment") -
/// retry pada metode yang SAMA (mis. tap ganda, retry setelah error
/// jaringan) memakai ulang id yang sama sehingga backend mengembalikan
/// transaksi yang sama, bukan membuat transaksi provider kedua. Beralih
/// ke metode LAIN (QRIS -> VA) SENGAJA memakai id baru - itu adalah niat
/// checkout yang berbeda.
/// ----------------------------------------------------------------------
class CheckoutController extends ChangeNotifier {
  final CreateCheckout _createCheckout;
  final PlanEntity plan;
  final BillingCycle billingCycle;

  final Map<PaymentMethodType, String> _attemptIdByMethod = {};

  CheckoutController({
    required CreateCheckout createCheckout,
    required this.plan,
    required this.billingCycle,
  }) : _createCheckout = createCheckout;

  CheckoutStatus status = CheckoutStatus.idle;
  String? errorMessage;
  PaymentTransactionEntity? transaction;

  /// Harga yang DITAMPILKAN sebelum submit - murni informasi, harga
  /// otoritatif tetap dihitung ulang server saat checkout (Bagian 8).
  int get displayedAmount => plan.priceFor(billingCycle);

  Future<bool> submit(PaymentMethodType method, {String? vaBank}) async {
    if (status == CheckoutStatus.submitting) return false;
    status = CheckoutStatus.submitting;
    errorMessage = null;
    notifyListeners();

    final attemptId = _attemptIdByMethod.putIfAbsent(method, () => const Uuid().v4());
    final result = await _createCheckout(
      planCode: plan.code,
      billingCycle: billingCycle,
      paymentMethod: method,
      checkoutAttemptId: attemptId,
      vaBank: vaBank,
    );

    var success = false;
    result.fold(
      (failure) {
        status = CheckoutStatus.error;
        errorMessage = failure.message;
      },
      (tx) {
        transaction = tx;
        status = CheckoutStatus.success;
        success = true;
      },
    );

    notifyListeners();
    return success;
  }
}
