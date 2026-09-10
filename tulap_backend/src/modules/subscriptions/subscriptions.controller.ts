import { Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { SubscriptionsService } from './subscriptions.service';

@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  /// GET /subscriptions/me - paket aktif + pemakaian kuota bulan
  /// berjalan milik user yang sedang login (Bagian 38 instruksi payment
  /// - "Paket Saya harus langsung berubah").
  @Get('me')
  getMySubscription(@CurrentUser() actor: AuthenticatedUser) {
    return this.subscriptionsService.getMySubscriptionView(actor.id);
  }

  /// POST /subscriptions/select-free - pilih paket Gratis (bukan lewat
  /// checkout QRIS/VA, Bagian 41 instruksi payment).
  @Post('select-free')
  selectFreePlan(@CurrentUser() actor: AuthenticatedUser) {
    return this.subscriptionsService.selectFreePlan(actor.id);
  }
}
