import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { PaymentTransactionStatus, RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { CreateCheckoutDto } from './dto/create-checkout.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /// POST /payments/checkout - membuat transaksi QRIS/VA baru (Bagian 7).
  @Post('checkout')
  checkout(@Body() dto: CreateCheckoutDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.paymentsService.checkout(actor.id, dto);
  }

  /// GET /payments - Riwayat Pembayaran milik user sendiri (Bagian 33).
  /// Didaftarkan SEBELUM ':publicReference' - lihat catatan yang sama
  /// di UsersController soal urutan route statis vs parameter.
  @Get()
  history(@CurrentUser() actor: AuthenticatedUser) {
    return this.paymentsService.listHistory(actor.id);
  }

  /// GET /payments/admin - visibilitas finance untuk ADMIN/SUPER_ADMIN
  /// (Bagian 37) - hanya role tsb, sesuai RBAC existing.
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Get('admin')
  adminList(
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
    @Query('status') status?: PaymentTransactionStatus,
  ) {
    return this.paymentsService.adminList({
      page: page ? parseInt(page, 10) : undefined,
      pageSize: pageSize ? parseInt(pageSize, 10) : undefined,
      status,
    });
  }

  /// GET /payments/:publicReference - Detail Pembayaran (Bagian 34).
  @Get(':publicReference')
  detail(
    @Param('publicReference') publicReference: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.paymentsService.getByReference(actor.id, publicReference);
  }

  /// POST /payments/:publicReference/check-status - "Cek Status
  /// Pembayaran" (Bagian 13, 26, 31) - backend yang bertanya ke
  /// provider, bukan client.
  @Post(':publicReference/check-status')
  checkStatus(
    @Param('publicReference') publicReference: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.paymentsService.reconcile(actor.id, publicReference);
  }
}
