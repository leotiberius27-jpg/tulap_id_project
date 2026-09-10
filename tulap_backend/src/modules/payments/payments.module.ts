import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuditModule } from '../audit/audit.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { PAYMENT_PROVIDER_ADAPTER } from './payment-provider.token';
import { MidtransProviderAdapter } from './providers/midtrans-provider.adapter';
import { WebhooksController } from './webhooks.controller';

/// PaymentsModule
/// ----------------------------------------------------------------------
/// Pemilihan provider aktif berdasarkan PAYMENT_PROVIDER env var (Bagian
/// 6 & 45 instruksi payment) - saat ini hanya "MIDTRANS" yang
/// diimplementasikan (satu-satunya provider dengan integrasi nyata di
/// codebase ini). Menambah provider lain di masa depan cukup menambah
/// case baru di factory ini - PaymentsService tidak perlu diubah karena
/// hanya bergantung pada PaymentProviderAdapter interface.
/// ----------------------------------------------------------------------
@Module({
  imports: [ConfigModule, AuditModule, SubscriptionsModule],
  controllers: [PaymentsController, WebhooksController],
  providers: [
    PaymentsService,
    MidtransProviderAdapter,
    {
      provide: PAYMENT_PROVIDER_ADAPTER,
      inject: [ConfigService, MidtransProviderAdapter],
      useFactory: (config: ConfigService, midtrans: MidtransProviderAdapter) => {
        const providerName = (config.get<string>('PAYMENT_PROVIDER') ?? 'MIDTRANS').toUpperCase();
        switch (providerName) {
          case 'MIDTRANS':
            return midtrans;
          default:
            throw new Error(
              `PAYMENT_PROVIDER='${providerName}' tidak dikenali. Provider yang tersedia: MIDTRANS.`,
            );
        }
      },
    },
  ],
  exports: [PaymentsService],
})
export class PaymentsModule {}
