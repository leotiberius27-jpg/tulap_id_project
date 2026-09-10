import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  PaymentMethod,
  PaymentTransaction,
  PaymentTransactionStatus,
  PlanCode,
  SubscriptionStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { getPlanActivityLimit, getPlanPrice } from '../subscriptions/plan-catalog';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { CreateCheckoutDto } from './dto/create-checkout.dto';
import {
  NormalizedPaymentStatus,
  PaymentProviderAdapter,
  VA_SUPPORTED_BANKS,
} from './payment-provider.interface';
import { PAYMENT_PROVIDER_ADAPTER } from './payment-provider.token';

const QRIS_EXPIRY_MINUTES = 30;
const VA_EXPIRY_MINUTES = 24 * 60;

/// Bentuk aman yang dikembalikan ke client - TIDAK PERNAH menyertakan
/// raw provider payload, secret, atau field internal (Bagian 34 & 44).
function toSafeTransactionView(tx: PaymentTransaction) {
  return {
    publicReference: tx.publicReference,
    planCode: tx.planCode,
    billingCycle: tx.billingCycle,
    amount: tx.amount,
    currency: tx.currency,
    paymentMethod: tx.paymentMethod,
    status: tx.status,
    qris:
      tx.paymentMethod === 'QRIS'
        ? { qrString: tx.qrString }
        : undefined,
    virtualAccount:
      tx.paymentMethod === 'VA'
        ? { bank: tx.vaBank, vaNumber: tx.vaNumber }
        : undefined,
    createdAt: tx.createdAt,
    expiresAt: tx.expiresAt,
    paidAt: tx.paidAt,
    failedAt: tx.failedAt,
    cancelledAt: tx.cancelledAt,
  };
}

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly subscriptions: SubscriptionsService,
    @Inject(PAYMENT_PROVIDER_ADAPTER) private readonly provider: PaymentProviderAdapter,
  ) {}

  /// checkout() - Bagian 8-14 instruksi payment.
  /// 1. Server menentukan harga (plan-catalog.ts, tidak pernah dari client).
  /// 2. Idempotent terhadap double-tap (Bagian 32) lewat dua lapis:
  ///    a. checkoutAttemptId unik - retry dengan attempt id yang sama
  ///       mengembalikan transaksi yang sama.
  ///    b. Transaksi CREATED/PENDING yang masih berlaku untuk kombinasi
  ///       plan+cycle+method yang sama juga dipakai ulang.
  async checkout(userId: string, dto: CreateCheckoutDto) {
    if (dto.planCode === PlanCode.GRATIS) {
      throw new BadRequestException(
        'Paket Gratis tidak memerlukan pembayaran. Gunakan endpoint pemilihan paket gratis.',
      );
    }

    if (dto.paymentMethod === PaymentMethod.VA) {
      const bank = (dto.vaBank ?? '').toLowerCase();
      if (!VA_SUPPORTED_BANKS.includes(bank as any)) {
        throw new BadRequestException(
          `Bank Virtual Account tidak didukung. Pilih salah satu: ${VA_SUPPORTED_BANKS.join(', ')}.`,
        );
      }
    }

    const existingByAttempt = await this.prisma.paymentTransaction.findUnique({
      where: { checkoutAttemptId: dto.checkoutAttemptId },
    });
    if (existingByAttempt) {
      if (existingByAttempt.userId !== userId) {
        throw new ForbiddenException('checkoutAttemptId tidak valid.');
      }
      return toSafeTransactionView(existingByAttempt);
    }

    const activeExisting = await this.prisma.paymentTransaction.findFirst({
      where: {
        userId,
        planCode: dto.planCode,
        billingCycle: dto.billingCycle,
        paymentMethod: dto.paymentMethod,
        status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] },
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (activeExisting) {
      return toSafeTransactionView(activeExisting);
    }

    const amount = getPlanPrice(dto.planCode, dto.billingCycle);
    const publicReference = `TLP${Date.now().toString(36).toUpperCase()}${randomUUID().replace(/-/g, '').slice(0, 12).toUpperCase()}`;

    let tx = await this.prisma.paymentTransaction.create({
      data: {
        publicReference,
        userId,
        planCode: dto.planCode,
        billingCycle: dto.billingCycle,
        amount,
        currency: 'IDR',
        paymentMethod: dto.paymentMethod,
        provider: this.provider.providerName,
        status: PaymentTransactionStatus.CREATED,
        checkoutAttemptId: dto.checkoutAttemptId,
      },
    });

    try {
      if (dto.paymentMethod === PaymentMethod.QRIS) {
        const result = await this.provider.createQrisPayment({
          orderId: publicReference,
          amount,
          expiresInMinutes: QRIS_EXPIRY_MINUTES,
        });
        tx = await this.prisma.paymentTransaction.update({
          where: { id: tx.id },
          data: {
            status: PaymentTransactionStatus.PENDING,
            providerTransactionId: result.providerTransactionId,
            qrString: result.qrString ?? result.qrImageUrl,
            expiresAt: result.expiresAt,
          },
        });
        await this.audit.log({
          actorId: userId,
          action: 'QRIS_CREATED',
          entity: 'PaymentTransaction',
          entityId: tx.id,
          metadata: { publicReference, planCode: dto.planCode, amount },
        });
      } else {
        const bank = (dto.vaBank ?? '').toLowerCase();
        const result = await this.provider.createVirtualAccountPayment({
          orderId: publicReference,
          amount,
          bank,
          expiresInMinutes: VA_EXPIRY_MINUTES,
        });
        tx = await this.prisma.paymentTransaction.update({
          where: { id: tx.id },
          data: {
            status: PaymentTransactionStatus.PENDING,
            providerTransactionId: result.providerTransactionId,
            vaBank: result.bank,
            vaNumber: result.vaNumber,
            expiresAt: result.expiresAt,
          },
        });
        await this.audit.log({
          actorId: userId,
          action: 'VA_CREATED',
          entity: 'PaymentTransaction',
          entityId: tx.id,
          metadata: { publicReference, planCode: dto.planCode, amount, bank: result.bank },
        });
      }
    } catch (error) {
      await this.prisma.paymentTransaction.update({
        where: { id: tx.id },
        data: { status: PaymentTransactionStatus.FAILED, failedAt: new Date() },
      });
      await this.audit.log({
        actorId: userId,
        action: 'PAYMENT_FAILED',
        entity: 'PaymentTransaction',
        entityId: tx.id,
        metadata: { publicReference, reason: 'provider_create_failed' },
      });
      throw error;
    }

    await this.audit.log({
      actorId: userId,
      action: 'PAYMENT_CREATED',
      entity: 'PaymentTransaction',
      entityId: tx.id,
      metadata: { publicReference, planCode: dto.planCode, billingCycle: dto.billingCycle },
    });

    return toSafeTransactionView(tx);
  }

  async getByReference(userId: string, publicReference: string, isAdmin = false) {
    const tx = await this.prisma.paymentTransaction.findUnique({ where: { publicReference } });
    if (!tx) throw new NotFoundException('Transaksi pembayaran tidak ditemukan.');
    if (!isAdmin && tx.userId !== userId) {
      throw new ForbiddenException('Anda tidak memiliki akses ke transaksi ini.');
    }
    return toSafeTransactionView(tx);
  }

  async listHistory(userId: string) {
    const items = await this.prisma.paymentTransaction.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return items.map(toSafeTransactionView);
  }

  /// reconcile() - "Cek Status Pembayaran" (Bagian 31 instruksi payment).
  /// Frontend TIDAK PERNAH memanggil provider langsung - selalu lewat
  /// backend, yang lalu memakai pipeline atomik yang SAMA dengan webhook.
  async reconcile(userId: string, publicReference: string) {
    const tx = await this.prisma.paymentTransaction.findUnique({ where: { publicReference } });
    if (!tx) throw new NotFoundException('Transaksi pembayaran tidak ditemukan.');
    if (tx.userId !== userId) {
      throw new ForbiddenException('Anda tidak memiliki akses ke transaksi ini.');
    }

    // Sudah status akhir - tidak perlu tanya provider lagi.
    if (tx.status !== PaymentTransactionStatus.CREATED && tx.status !== PaymentTransactionStatus.PENDING) {
      return toSafeTransactionView(tx);
    }

    if (tx.expiresAt && tx.expiresAt.getTime() < Date.now()) {
      const expired = await this.prisma.paymentTransaction.updateMany({
        where: { id: tx.id, status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] } },
        data: { status: PaymentTransactionStatus.EXPIRED },
      });
      if (expired.count > 0) {
        await this.audit.log({
          actorId: userId,
          action: 'PAYMENT_EXPIRED',
          entity: 'PaymentTransaction',
          entityId: tx.id,
          metadata: { publicReference },
        });
      }
      const refreshed = await this.prisma.paymentTransaction.findUniqueOrThrow({ where: { id: tx.id } });
      return toSafeTransactionView(refreshed);
    }

    if (!tx.providerTransactionId) {
      return toSafeTransactionView(tx);
    }

    const statusResult = await this.provider.getPaymentStatus(tx.publicReference);
    await this.audit.log({
      actorId: userId,
      action: 'PAYMENT_RECONCILED',
      entity: 'PaymentTransaction',
      entityId: tx.id,
      metadata: { publicReference, providerStatus: statusResult.rawStatus },
    });

    const updated = await this.applyNormalizedStatus(tx, statusResult.normalizedStatus, {
      providerTransactionId: statusResult.providerTransactionId,
      grossAmount: statusResult.grossAmount,
    });
    return toSafeTransactionView(updated);
  }

  /// handleWebhook() - satu-satunya jalur MASUK dari provider. Webhook
  /// adalah source of truth (Bagian 17) - endpoint publik (@Public()),
  /// diautentikasi lewat signature provider, BUKAN JWT.
  async handleWebhook(payload: Record<string, unknown>): Promise<{ status: string }> {
    if (!this.provider.verifyWebhookSignature(payload)) {
      this.logger.warn('webhook_rejected: signature tidak valid');
      throw new ForbiddenException('Invalid signature.');
    }

    const event = this.provider.normalizeWebhookPayload(payload);
    this.logger.log(`webhook_verified: order=${event.orderId} status=${event.rawStatus}`);

    try {
      await this.prisma.processed_Webhook_Event.create({
        data: { provider: this.provider.providerName, eventId: event.eventId },
      });
    } catch {
      // Unique constraint violation -> notifikasi ini sudah pernah diproses.
      this.logger.log(`duplicate_webhook_ignored: ${event.eventId}`);
      return { status: 'duplicate_ignored' };
    }

    const tx = await this.prisma.paymentTransaction.findUnique({
      where: { publicReference: event.orderId },
    });
    if (!tx) {
      this.logger.warn(`webhook_received untuk order_id tidak dikenal: ${event.orderId}`);
      return { status: 'unknown_order' };
    }

    await this.applyNormalizedStatus(tx, event.normalizedStatus, {
      providerTransactionId: event.providerTransactionId,
      grossAmount: event.grossAmount,
    });

    return { status: 'ok' };
  }

  /// Menerapkan status ternormalisasi (dari webhook ATAU reconciliation
  /// manual - Bagian 20 "Concurrent Verification", keduanya HARUS masuk
  /// pipeline yang sama) ke satu PaymentTransaction.
  private async applyNormalizedStatus(
    tx: PaymentTransaction,
    normalizedStatus: NormalizedPaymentStatus,
    verified: { providerTransactionId: string; grossAmount: number },
  ): Promise<PaymentTransaction> {
    switch (normalizedStatus) {
      case 'PAID':
        return this.completePaidTransaction(tx, verified);
      case 'PENDING': {
        await this.prisma.paymentTransaction.updateMany({
          where: { id: tx.id, status: PaymentTransactionStatus.CREATED },
          data: { status: PaymentTransactionStatus.PENDING, providerTransactionId: verified.providerTransactionId },
        });
        break;
      }
      case 'FAILED': {
        const result = await this.prisma.paymentTransaction.updateMany({
          where: { id: tx.id, status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] } },
          data: { status: PaymentTransactionStatus.FAILED, failedAt: new Date() },
        });
        if (result.count > 0) {
          await this.audit.log({
            action: 'PAYMENT_FAILED',
            entity: 'PaymentTransaction',
            entityId: tx.id,
            metadata: { publicReference: tx.publicReference },
          });
        }
        break;
      }
      case 'EXPIRED': {
        const result = await this.prisma.paymentTransaction.updateMany({
          where: { id: tx.id, status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] } },
          data: { status: PaymentTransactionStatus.EXPIRED },
        });
        if (result.count > 0) {
          await this.audit.log({
            action: 'PAYMENT_EXPIRED',
            entity: 'PaymentTransaction',
            entityId: tx.id,
            metadata: { publicReference: tx.publicReference },
          });
        }
        break;
      }
      case 'CANCELLED': {
        await this.prisma.paymentTransaction.updateMany({
          where: { id: tx.id, status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] } },
          data: { status: PaymentTransactionStatus.CANCELLED, cancelledAt: new Date() },
        });
        break;
      }
      case 'REFUNDED': {
        // Hanya dicatat - TIDAK otomatis mencabut subscription (Bagian 42:
        // jangan diam-diam memutuskan business rule yang belum disetujui).
        await this.prisma.paymentTransaction.updateMany({
          where: { id: tx.id, status: PaymentTransactionStatus.PAID },
          data: { status: PaymentTransactionStatus.REFUNDED, refundedAt: new Date() },
        });
        break;
      }
    }

    return this.prisma.paymentTransaction.findUniqueOrThrow({ where: { id: tx.id } });
  }

  /// completePaidTransaction() - SATU-SATUNYA jalur aktivasi subscription
  /// (Bagian 21 instruksi payment - "Atomic Payment Completion").
  /// Compare-and-set lewat updateMany(WHERE status IN (...)) adalah
  /// operasi atomik tunggal di level database - inilah yang membuat
  /// webhook ganda ATAU webhook+reconciliation yang datang bersamaan
  /// (Bagian 20 & 58) tetap hanya menghasilkan SATU aktivasi: siapa pun
  /// yang "menang" race ini (count===1) adalah satu-satunya yang
  /// melanjutkan ke aktivasi subscription; yang kalah (count===0)
  /// berhenti diam (no-op idempoten).
  private async completePaidTransaction(
    tx: PaymentTransaction,
    verified: { providerTransactionId: string; grossAmount: number },
  ): Promise<PaymentTransaction> {
    if (verified.grossAmount !== tx.amount) {
      this.logger.error(
        `SECURITY: amount mismatch pada ${tx.publicReference} - diharapkan ${tx.amount}, provider melaporkan ${verified.grossAmount}. Aktivasi DIBATALKAN.`,
      );
      await this.audit.log({
        action: 'PAYMENT_AMOUNT_MISMATCH',
        entity: 'PaymentTransaction',
        entityId: tx.id,
        metadata: { expected: tx.amount, received: verified.grossAmount },
      });
      return tx;
    }

    const paidAt = new Date();
    const limit = getPlanActivityLimit(tx.planCode);

    const result = await this.prisma.$transaction(async (db) => {
      const claim = await db.paymentTransaction.updateMany({
        where: { id: tx.id, status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] } },
        data: {
          status: PaymentTransactionStatus.PAID,
          paidAt,
          providerTransactionId: verified.providerTransactionId,
        },
      });

      if (claim.count === 0) {
        // Sudah diaktivasi oleh request lain (webhook duplikat atau
        // reconciliation yang datang bersamaan) - no-op idempoten.
        return null;
      }

      const periodStart = paidAt;
      const periodEnd = this.subscriptions.calculatePeriodEnd(periodStart, tx.billingCycle);

      const subscription = await db.subscription.upsert({
        where: { userId: tx.userId },
        create: {
          userId: tx.userId,
          planCode: tx.planCode,
          billingCycle: tx.billingCycle,
          status: SubscriptionStatus.ACTIVE,
          currentPeriodStart: periodStart,
          currentPeriodEnd: periodEnd,
        },
        update: {
          planCode: tx.planCode,
          billingCycle: tx.billingCycle,
          status: SubscriptionStatus.ACTIVE,
          currentPeriodStart: periodStart,
          currentPeriodEnd: periodEnd,
        },
      });

      await db.paymentTransaction.update({
        where: { id: tx.id },
        data: { subscriptionId: subscription.id },
      });

      await db.audit_Log.create({
        data: {
          actorId: tx.userId,
          action: 'PAYMENT_PAID',
          entity: 'PaymentTransaction',
          entityId: tx.id,
          metadata: { publicReference: tx.publicReference, planCode: tx.planCode, amount: tx.amount },
        },
      });
      await db.audit_Log.create({
        data: {
          actorId: tx.userId,
          action: 'SUBSCRIPTION_ACTIVATED',
          entity: 'Subscription',
          entityId: subscription.id,
          metadata: { planCode: tx.planCode, billingCycle: tx.billingCycle, activityLimit: limit },
        },
      });

      return subscription;
    });

    if (result) {
      this.logger.log(
        `subscription_activated: user=${tx.userId} plan=${tx.planCode} via=${tx.publicReference}`,
      );
    }

    return this.prisma.paymentTransaction.findUniqueOrThrow({ where: { id: tx.id } });
  }

  // ================================================================
  // ADMIN VISIBILITY (Bagian 37) - hanya ringkasan, tidak ada secret.
  // ================================================================
  async adminList(params: { page?: number; pageSize?: number; status?: PaymentTransactionStatus }) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const where = params.status ? { status: params.status } : {};

    const [items, total] = await Promise.all([
      this.prisma.paymentTransaction.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { id: true, fullName: true, email: true } } },
      }),
      this.prisma.paymentTransaction.count({ where }),
    ]);

    return {
      items: items.map((tx) => ({
        ...toSafeTransactionView(tx),
        user: tx.user,
      })),
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }
}
