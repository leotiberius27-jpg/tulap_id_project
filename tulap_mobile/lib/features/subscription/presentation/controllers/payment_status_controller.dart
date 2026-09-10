import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/usecases/check_payment_status.dart';

/// PaymentStatusController
/// ----------------------------------------------------------------------
/// Mengelola status satu transaksi QRIS/VA yang sedang menunggu
/// pembayaran (Bagian 13 instruksi payment - "QRIS Polling"). Polling
/// terkontrol dengan backoff (BUKAN interval tetap agresif), berhenti
/// otomatis saat status final (PAID/FAILED/EXPIRED/CANCELLED) atau
/// controller di-dispose (layar ditutup/di-background).
///
/// Kegagalan jaringan saat polling TIDAK PERNAH diperlakukan sebagai
/// FAILED (Bagian 29) - `lastCheckFailed` hanya menampilkan pesan netral,
/// status transaksi tetap seperti sebelumnya sampai backend benar-benar
/// menjawab.
/// ----------------------------------------------------------------------
class PaymentStatusController extends ChangeNotifier {
  final CheckPaymentStatus _checkPaymentStatus;

  PaymentTransactionEntity transaction;
  bool isChecking = false;
  bool lastCheckFailed = false;

  Timer? _pollTimer;
  int _pollAttempt = 0;
  static const _backoffSeconds = [3, 5, 8, 13, 20, 30];

  PaymentStatusController({
    required CheckPaymentStatus checkPaymentStatus,
    required this.transaction,
  }) : _checkPaymentStatus = checkPaymentStatus {
    _schedulePollIfNeeded();
  }

  void _schedulePollIfNeeded() {
    _pollTimer?.cancel();
    if (transaction.status.isTerminal) return;

    final delay = _backoffSeconds[_pollAttempt.clamp(0, _backoffSeconds.length - 1)];
    _pollTimer = Timer(Duration(seconds: delay), () {
      _pollAttempt++;
      refresh(silent: true);
    });
  }

  /// Dipanggil tombol "Cek Status Pembayaran" (silent=false, menampilkan
  /// loading) ATAU polling background (silent=true).
  Future<void> refresh({bool silent = false}) async {
    if (isChecking) return;
    isChecking = true;
    if (!silent) notifyListeners();

    final result = await _checkPaymentStatus(transaction.publicReference);
    isChecking = false;

    result.fold(
      (failure) {
        lastCheckFailed = true;
      },
      (tx) {
        lastCheckFailed = false;
        transaction = tx;
      },
    );

    notifyListeners();
    _schedulePollIfNeeded();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
