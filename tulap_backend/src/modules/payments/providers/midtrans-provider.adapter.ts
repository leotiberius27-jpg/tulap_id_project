import { BadGatewayException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import {
  CreateQrisPaymentParams,
  CreateQrisPaymentResult,
  CreateVirtualAccountPaymentParams,
  CreateVirtualAccountPaymentResult,
  NormalizedPaymentStatus,
  NormalizedWebhookEvent,
  PaymentProviderAdapter,
  ProviderStatusResult,
} from '../payment-provider.interface';

/// MidtransProviderAdapter
/// ----------------------------------------------------------------------
/// Implementasi PaymentProviderAdapter untuk Midtrans Core API v2
/// (server-to-server, BUKAN Snap redirect) - dipilih karena mendukung
/// QRIS + Virtual Account + webhook (HTTP Notification) + status
/// inquiry dalam satu API, dan rekening settlement dikonfigurasi lewat
/// merchant dashboard Midtrans (Bagian 6 & 35 instruksi payment).
///
/// PENTING - lihat laporan akhir implementasi:
/// - Butuh MIDTRANS_SERVER_KEY dari dashboard Midtrans (sandbox/live).
/// - Apakah SeaBank termasuk daftar rekening settlement yang didukung
///   Midtrans BELUM DIKONFIRMASI di sini - JANGAN diasumsikan tersedia
///   sebelum dicek langsung di merchant dashboard/menghubungi Midtrans.
///
/// Endpoint & format request/response mengikuti dokumentasi resmi
/// Midtrans Core API (https://docs.midtrans.com/reference/core-api-overview) -
/// TIDAK ada field yang dikarang; jika field respons yang diharapkan
/// (mis. `qr_string`) ternyata tidak dikirim provider pada akun
/// tertentu, adapter ini fallback ke `actions[].url` (generate-qr-code),
/// bukan gagal diam-diam.
/// ----------------------------------------------------------------------
@Injectable()
export class MidtransProviderAdapter implements PaymentProviderAdapter {
  readonly providerName = 'MIDTRANS';

  private readonly logger = new Logger(MidtransProviderAdapter.name);
  private readonly serverKey: string;
  private readonly baseUrl: string;

  constructor(private readonly config: ConfigService) {
    this.serverKey = this.config.get<string>('MIDTRANS_SERVER_KEY') ?? '';
    const environment = this.config.get<string>('PAYMENT_ENVIRONMENT') ?? 'sandbox';
    this.baseUrl =
      environment === 'production'
        ? 'https://api.midtrans.com/v2'
        : 'https://api.sandbox.midtrans.com/v2';

    if (!this.serverKey) {
      this.logger.warn(
        'MIDTRANS_SERVER_KEY belum diisi di environment - checkout QRIS/VA akan gagal sampai credential sandbox/production dikonfigurasi.',
      );
    }
  }

  private authHeader(): string {
    return 'Basic ' + Buffer.from(`${this.serverKey}:`).toString('base64');
  }

  private async request<T = any>(path: string, options: RequestInit = {}): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: this.authHeader(),
        ...(options.headers ?? {}),
      },
    });

    const body = await response.json().catch(() => ({}));

    // Midtrans mengembalikan 2xx untuk sukses dan 4xx/5xx untuk error,
    // dengan `status_message` yang aman ditampilkan (bukan secret).
    if (!response.ok) {
      this.logger.error(
        `Midtrans request gagal (${response.status}): ${body?.status_message ?? 'unknown error'}`,
      );
      throw new BadGatewayException(
        'Payment provider sedang tidak dapat memproses transaksi. Silakan coba lagi.',
      );
    }

    return body as T;
  }

  async createQrisPayment(params: CreateQrisPaymentParams): Promise<CreateQrisPaymentResult> {
    const body = await this.request<any>('/charge', {
      method: 'POST',
      body: JSON.stringify({
        payment_type: 'qris',
        transaction_details: {
          order_id: params.orderId,
          gross_amount: params.amount,
        },
        qris: { acquirer: 'gopay' },
        custom_expiry: {
          expiry_duration: params.expiresInMinutes,
          unit: 'minute',
        },
      }),
    });

    const generateQrAction = Array.isArray(body.actions)
      ? body.actions.find((a: any) => a?.name === 'generate-qr-code')
      : undefined;

    const expiresAt = body.expiry_time
      ? new Date(body.expiry_time.replace(' ', 'T'))
      : new Date(Date.now() + params.expiresInMinutes * 60_000);

    return {
      providerTransactionId: body.transaction_id,
      qrString: body.qr_string ?? null,
      qrImageUrl: generateQrAction?.url ?? null,
      expiresAt,
      rawStatus: body.transaction_status,
    };
  }

  async createVirtualAccountPayment(
    params: CreateVirtualAccountPaymentParams,
  ): Promise<CreateVirtualAccountPaymentResult> {
    const body = await this.request<any>('/charge', {
      method: 'POST',
      body: JSON.stringify({
        payment_type: 'bank_transfer',
        transaction_details: {
          order_id: params.orderId,
          gross_amount: params.amount,
        },
        bank_transfer: { bank: params.bank },
        custom_expiry: {
          expiry_duration: params.expiresInMinutes,
          unit: 'minute',
        },
      }),
    });

    const vaEntry = Array.isArray(body.va_numbers) ? body.va_numbers[0] : undefined;
    const expiresAt = body.expiry_time
      ? new Date(body.expiry_time.replace(' ', 'T'))
      : new Date(Date.now() + params.expiresInMinutes * 60_000);

    if (!vaEntry?.va_number) {
      this.logger.error(`Midtrans tidak mengembalikan nomor VA untuk order ${params.orderId}`);
      throw new BadGatewayException(
        'Payment provider tidak mengembalikan nomor Virtual Account. Silakan coba lagi.',
      );
    }

    return {
      providerTransactionId: body.transaction_id,
      bank: vaEntry.bank ?? params.bank,
      vaNumber: vaEntry.va_number,
      expiresAt,
      rawStatus: body.transaction_status,
    };
  }

  async getPaymentStatus(orderId: string): Promise<ProviderStatusResult> {
    const body = await this.request<any>(`/${encodeURIComponent(orderId)}/status`, {
      method: 'GET',
    });

    return {
      providerTransactionId: body.transaction_id,
      normalizedStatus: this.normalizeStatus(body.transaction_status, body.fraud_status),
      rawStatus: body.transaction_status,
      grossAmount: Math.round(parseFloat(body.gross_amount)),
      paidAt:
        body.transaction_status === 'settlement' || body.transaction_status === 'capture'
          ? new Date((body.settlement_time ?? body.transaction_time ?? Date.now()).toString().replace(' ', 'T'))
          : null,
    };
  }

  /// Signature verification RESMI Midtrans (HTTP Notification):
  /// signature_key === SHA512(order_id + status_code + gross_amount + ServerKey)
  /// https://docs.midtrans.com/docs/https-notification-webhooks
  verifyWebhookSignature(payload: Record<string, unknown>): boolean {
    const orderId = String(payload.order_id ?? '');
    const statusCode = String(payload.status_code ?? '');
    const grossAmount = String(payload.gross_amount ?? '');
    const receivedSignature = String(payload.signature_key ?? '');

    if (!orderId || !statusCode || !grossAmount || !receivedSignature) {
      return false;
    }

    const expectedSignature = crypto
      .createHash('sha512')
      .update(orderId + statusCode + grossAmount + this.serverKey)
      .digest('hex');

    const expectedBuf = Buffer.from(expectedSignature, 'utf8');
    const receivedBuf = Buffer.from(receivedSignature.toLowerCase(), 'utf8');

    if (expectedBuf.length !== receivedBuf.length) return false;
    return crypto.timingSafeEqual(expectedBuf, receivedBuf);
  }

  normalizeWebhookPayload(payload: Record<string, unknown>): NormalizedWebhookEvent {
    const orderId = String(payload.order_id ?? '');
    const transactionId = String(payload.transaction_id ?? '');
    const transactionStatus = String(payload.transaction_status ?? '');
    const fraudStatus = payload.fraud_status ? String(payload.fraud_status) : undefined;

    return {
      orderId,
      providerTransactionId: transactionId,
      normalizedStatus: this.normalizeStatus(transactionStatus, fraudStatus),
      rawStatus: transactionStatus,
      grossAmount: Math.round(parseFloat(String(payload.gross_amount ?? '0'))),
      eventId: `${transactionId}:${transactionStatus}`,
    };
  }

  async cancelPayment(orderId: string): Promise<void> {
    await this.request(`/${encodeURIComponent(orderId)}/cancel`, { method: 'POST' });
  }

  private normalizeStatus(
    transactionStatus: string,
    fraudStatus?: string,
  ): NormalizedPaymentStatus {
    switch (transactionStatus) {
      case 'capture':
        return fraudStatus === 'accept' ? 'PAID' : 'PENDING';
      case 'settlement':
        return 'PAID';
      case 'pending':
        return 'PENDING';
      case 'deny':
        return 'FAILED';
      case 'cancel':
        return 'CANCELLED';
      case 'expire':
        return 'EXPIRED';
      case 'refund':
      case 'partial_refund':
        return 'REFUNDED';
      default:
        return 'PENDING';
    }
  }
}
