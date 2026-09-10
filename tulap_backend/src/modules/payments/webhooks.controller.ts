import { Body, Controller, Post } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';
import { PaymentsService } from './payments.service';

/// WebhooksController
/// ----------------------------------------------------------------------
/// POST /webhooks/payments/midtrans - HTTP Notification resmi Midtrans
/// (Bagian 17 instruksi payment - "Webhook Adalah Source of Truth").
/// @Public() KARENA Midtrans tidak mengirim JWT - autentikasi dilakukan
/// lewat signature_key di dalam body (Bagian 18), diverifikasi di
/// PaymentsService.handleWebhook() -> MidtransProviderAdapter.
/// verifyWebhookSignature(). Daftarkan URL ini di merchant dashboard
/// Midtrans (Settings > Configuration > Payment Notification URL).
/// ----------------------------------------------------------------------
@Controller('webhooks/payments')
export class WebhooksController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Public()
  @Post('midtrans')
  handleMidtrans(@Body() body: Record<string, unknown>) {
    return this.paymentsService.handleWebhook(body);
  }
}
