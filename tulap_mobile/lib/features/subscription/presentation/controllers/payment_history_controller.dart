import 'package:flutter/foundation.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/usecases/get_payment_history.dart';

enum PaymentHistoryStatus { loading, loaded, error }

class PaymentHistoryController extends ChangeNotifier {
  final GetPaymentHistory _getPaymentHistory;
  PaymentHistoryController({required GetPaymentHistory getPaymentHistory})
    : _getPaymentHistory = getPaymentHistory;

  PaymentHistoryStatus status = PaymentHistoryStatus.loading;
  String? errorMessage;
  List<PaymentTransactionEntity> items = const [];

  Future<void> load() async {
    status = PaymentHistoryStatus.loading;
    notifyListeners();

    final result = await _getPaymentHistory();
    result.fold(
      (failure) {
        status = PaymentHistoryStatus.error;
        errorMessage = failure.message;
      },
      (list) {
        items = list;
        status = PaymentHistoryStatus.loaded;
      },
    );
    notifyListeners();
  }
}
