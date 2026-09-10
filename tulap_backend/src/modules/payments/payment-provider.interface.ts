/// PaymentProviderAdapter
/// ----------------------------------------------------------------------
/// Kontrak yang HARUS diimplementasikan oleh setiap payment gateway yang
/// dipakai Tulap.id (Bagian 5 instruksi payment - "Payment Provider
/// Abstraction"). PaymentsService HANYA bergantung pada interface ini,
/// tidak pernah pada satu provider secara langsung - mengganti/menambah
/// provider di masa depan tidak perlu menyentuh PaymentsService.
/// ----------------------------------------------------------------------

export type NormalizedPaymentStatus =
  | 'PENDING'
  | 'PAID'
  | 'FAILED'
  | 'EXPIRED'
  | 'CANCELLED'
  | 'REFUNDED';

export interface CreateQrisPaymentParams {
  /// Dipakai sebagai order_id/reference di sisi provider - HARUS unik,
  /// diisi dengan PaymentTransaction.publicReference.
  orderId: string;
  /// Rupiah bulat - SUDAH ditentukan server dari plan-catalog.ts.
  amount: number;
  expiresInMinutes: number;
}

export interface CreateQrisPaymentResult {
  providerTransactionId: string;
  /// Payload QRIS dinamis mentah dari provider (dipakai render QR code
  /// di client) - null jika provider hanya memberi URL gambar.
  qrString: string | null;
  /// URL gambar QR dari provider - dipakai sebagai fallback jika
  /// qrString tidak tersedia.
  qrImageUrl: string | null;
  expiresAt: Date;
  rawStatus: string;
}

export interface CreateVirtualAccountPaymentParams {
  orderId: string;
  amount: number;
  /// Kode bank sesuai daftar yang didukung provider (mis. "bca", "bni").
  bank: string;
  expiresInMinutes: number;
}

export interface CreateVirtualAccountPaymentResult {
  providerTransactionId: string;
  bank: string;
  vaNumber: string;
  expiresAt: Date;
  rawStatus: string;
}

export interface ProviderStatusResult {
  providerTransactionId: string;
  normalizedStatus: NormalizedPaymentStatus;
  rawStatus: string;
  /// Nominal yang benar-benar dikonfirmasi provider - WAJIB dicocokkan
  /// dengan PaymentTransaction.amount sebelum aktivasi (Bagian 17 poin 7).
  grossAmount: number;
  paidAt: Date | null;
}

export interface NormalizedWebhookEvent {
  orderId: string;
  providerTransactionId: string;
  normalizedStatus: NormalizedPaymentStatus;
  rawStatus: string;
  grossAmount: number;
  /// ID unik notifikasi ini di sisi provider - dipakai sebagai kunci
  /// dedupe Processed_Webhook_Event (Bagian 19).
  eventId: string;
}

export interface PaymentProviderAdapter {
  readonly providerName: string;

  createQrisPayment(params: CreateQrisPaymentParams): Promise<CreateQrisPaymentResult>;

  createVirtualAccountPayment(
    params: CreateVirtualAccountPaymentParams,
  ): Promise<CreateVirtualAccountPaymentResult>;

  getPaymentStatus(orderId: string): Promise<ProviderStatusResult>;

  /// Memverifikasi keaslian request webhook SESUAI spesifikasi resmi
  /// provider (Bagian 18) - HARUS menolak (return false) jika signature
  /// tidak valid, bukan menebak.
  verifyWebhookSignature(payload: Record<string, unknown>): boolean;

  normalizeWebhookPayload(payload: Record<string, unknown>): NormalizedWebhookEvent;

  cancelPayment?(orderId: string): Promise<void>;
}

export const VA_SUPPORTED_BANKS = ['bca', 'bni', 'bri', 'permata'] as const;
export type SupportedVaBank = (typeof VA_SUPPORTED_BANKS)[number];
