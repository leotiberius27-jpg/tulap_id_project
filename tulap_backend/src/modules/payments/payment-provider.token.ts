/// Injection token untuk PaymentProviderAdapter aktif - lihat
/// payments.module.ts untuk pemilihan implementasi berdasarkan
/// PAYMENT_PROVIDER env var (Bagian 6 instruksi payment).
export const PAYMENT_PROVIDER_ADAPTER = Symbol('PAYMENT_PROVIDER_ADAPTER');
