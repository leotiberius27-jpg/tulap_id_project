/// PaymentTransactionStatus
/// ----------------------------------------------------------------------
/// Status ternormalisasi transaksi pembayaran - identik dengan enum
/// PaymentTransactionStatus di backend (Bagian 9 instruksi payment).
/// Backend adalah SATU-SATUNYA yang boleh mengubah status ini (lewat
/// webhook/reconciliation) - mobile hanya membaca.
/// ----------------------------------------------------------------------
enum PaymentTransactionStatus {
  created,
  pending,
  paid,
  expired,
  failed,
  cancelled,
  refunded;

  static PaymentTransactionStatus fromApiValue(String value) => switch (value) {
    'CREATED' => PaymentTransactionStatus.created,
    'PENDING' => PaymentTransactionStatus.pending,
    'PAID' => PaymentTransactionStatus.paid,
    'EXPIRED' => PaymentTransactionStatus.expired,
    'FAILED' => PaymentTransactionStatus.failed,
    'CANCELLED' => PaymentTransactionStatus.cancelled,
    'REFUNDED' => PaymentTransactionStatus.refunded,
    _ => PaymentTransactionStatus.pending,
  };

  bool get isTerminal => this != PaymentTransactionStatus.created && this != PaymentTransactionStatus.pending;

  bool get isWaitingPayment =>
      this == PaymentTransactionStatus.created || this == PaymentTransactionStatus.pending;
}
