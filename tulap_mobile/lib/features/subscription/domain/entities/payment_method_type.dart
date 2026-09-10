/// PaymentMethodType
/// ----------------------------------------------------------------------
/// Dua metode pembayaran resmi Tulap.id (Bagian 1 instruksi payment) -
/// QRIS untuk aplikasi bank/e-wallet apa pun yang mendukung jaringan
/// QRIS, Transfer Virtual Account untuk channel bank yang didukung
/// provider. TIDAK terikat SeaBank - SeaBank hanya rekening tujuan
/// settlement merchant (Bagian 4).
/// ----------------------------------------------------------------------
enum PaymentMethodType {
  qris,
  virtualAccount;

  String get apiValue => switch (this) {
    PaymentMethodType.qris => 'QRIS',
    PaymentMethodType.virtualAccount => 'VA',
  };

  static PaymentMethodType fromApiValue(String value) => switch (value) {
    'VA' => PaymentMethodType.virtualAccount,
    _ => PaymentMethodType.qris,
  };
}

/// Daftar bank VA yang didukung - HARUS identik dengan VA_SUPPORTED_BANKS
/// di backend (tulap_backend/src/modules/payments/payment-provider.interface.ts).
/// Checkout dengan kode bank di luar daftar ini ditolak backend.
const List<String> vaSupportedBanks = ['bca', 'bni', 'bri', 'permata'];
