import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PaymentTransactionStatus, PlanCode } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { PaymentsService } from './payments.service';
import { PAYMENT_PROVIDER_ADAPTER } from './payment-provider.token';

/// PaymentsService.spec
/// ----------------------------------------------------------------------
/// Menguji bagian PALING kritikal dari instruksi payment: server
/// menentukan harga (Bagian 8), idempotency checkout & webhook
/// (Bagian 19, 32), dan atomic completion / concurrency (Bagian 20, 21,
/// 58) - BUKAN detail Midtrans (sudah diverifikasi manual lewat
/// sandbox call di RUNBOOK).
/// ----------------------------------------------------------------------
describe('PaymentsService', () => {
  let service: PaymentsService;
  let prisma: any;
  let provider: any;

  const userId = 'user_1';

  const makeTx = (overrides: Partial<any> = {}) => ({
    id: 'tx_1',
    publicReference: 'TLPREF1',
    userId,
    planCode: PlanCode.PRO,
    billingCycle: 'MONTHLY',
    amount: 39000,
    currency: 'IDR',
    paymentMethod: 'QRIS',
    provider: 'MIDTRANS',
    providerTransactionId: 'midtrans_tx_1',
    status: PaymentTransactionStatus.PENDING,
    checkoutAttemptId: 'attempt_1',
    expiresAt: new Date(Date.now() + 60_000),
    createdAt: new Date(),
    ...overrides,
  });

  beforeEach(async () => {
    prisma = {
      paymentTransaction: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
      },
      processed_Webhook_Event: {
        create: jest.fn(),
      },
      subscription: {
        upsert: jest.fn(),
      },
      audit_Log: {
        create: jest.fn(),
      },
      $transaction: jest.fn(async (cb: any) => cb(prisma)),
    };

    provider = {
      providerName: 'MIDTRANS',
      createQrisPayment: jest.fn(),
      createVirtualAccountPayment: jest.fn(),
      getPaymentStatus: jest.fn(),
      verifyWebhookSignature: jest.fn(),
      normalizeWebhookPayload: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuditService, useValue: { log: jest.fn() } },
        {
          provide: SubscriptionsService,
          useValue: { calculatePeriodEnd: jest.fn(() => new Date('2026-10-08')) },
        },
        { provide: PAYMENT_PROVIDER_ADAPTER, useValue: provider },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
  });

  describe('checkout - Bagian 8: Server Menentukan Harga', () => {
    it('menolak checkout untuk paket GRATIS', async () => {
      await expect(
        service.checkout(userId, {
          planCode: PlanCode.GRATIS,
          billingCycle: 'MONTHLY' as any,
          paymentMethod: 'QRIS' as any,
          checkoutAttemptId: 'a1',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('SELALU memakai harga dari plan-catalog, bukan dari client (client tidak bisa mengirim amount karena DTO tidak punya field itu)', async () => {
      prisma.paymentTransaction.findUnique.mockResolvedValue(null);
      prisma.paymentTransaction.findFirst.mockResolvedValue(null);
      prisma.paymentTransaction.create.mockResolvedValue(makeTx({ status: 'CREATED' }));
      provider.createQrisPayment.mockResolvedValue({
        providerTransactionId: 'midtrans_tx_1',
        qrString: '00020101...',
        qrImageUrl: null,
        expiresAt: new Date(Date.now() + 1_800_000),
        rawStatus: 'pending',
      });
      prisma.paymentTransaction.update.mockResolvedValue(makeTx());

      await service.checkout(userId, {
        planCode: PlanCode.PRO,
        billingCycle: 'MONTHLY' as any,
        paymentMethod: 'QRIS' as any,
        checkoutAttemptId: 'a1',
      });

      // PRO monthly = Rp39.000 (plan-catalog.ts) - TIDAK PERNAH dari request.
      expect(prisma.paymentTransaction.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ amount: 39000 }) }),
      );
      expect(provider.createQrisPayment).toHaveBeenCalledWith(
        expect.objectContaining({ amount: 39000 }),
      );
    });
  });

  describe('checkout - Bagian 32: mencegah double payment', () => {
    it('mengembalikan transaksi yang sama jika checkoutAttemptId sudah pernah dipakai (retry setelah double-tap)', async () => {
      const existing = makeTx();
      prisma.paymentTransaction.findUnique.mockResolvedValue(existing);

      const result = await service.checkout(userId, {
        planCode: PlanCode.PRO,
        billingCycle: 'MONTHLY' as any,
        paymentMethod: 'QRIS' as any,
        checkoutAttemptId: 'attempt_1',
      });

      expect(result.publicReference).toBe(existing.publicReference);
      expect(prisma.paymentTransaction.create).not.toHaveBeenCalled();
      expect(provider.createQrisPayment).not.toHaveBeenCalled();
    });

    it('menolak jika checkoutAttemptId sudah dipakai user lain', async () => {
      prisma.paymentTransaction.findUnique.mockResolvedValue(makeTx({ userId: 'other_user' }));

      await expect(
        service.checkout(userId, {
          planCode: PlanCode.PRO,
          billingCycle: 'MONTHLY' as any,
          paymentMethod: 'QRIS' as any,
          checkoutAttemptId: 'attempt_1',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('mengembalikan checkout PENDING yang masih berlaku (attemptId baru, tap ganda tanpa reuse attemptId)', async () => {
      const active = makeTx({ checkoutAttemptId: 'attempt_other' });
      prisma.paymentTransaction.findUnique.mockResolvedValue(null);
      prisma.paymentTransaction.findFirst.mockResolvedValue(active);

      const result = await service.checkout(userId, {
        planCode: PlanCode.PRO,
        billingCycle: 'MONTHLY' as any,
        paymentMethod: 'QRIS' as any,
        checkoutAttemptId: 'attempt_new',
      });

      expect(result.publicReference).toBe(active.publicReference);
      expect(prisma.paymentTransaction.create).not.toHaveBeenCalled();
    });
  });

  describe('handleWebhook - Bagian 17 & 18: source of truth & signature', () => {
    it('menolak webhook dengan signature tidak valid', async () => {
      provider.verifyWebhookSignature.mockReturnValue(false);

      await expect(service.handleWebhook({ order_id: 'x' })).rejects.toThrow(ForbiddenException);
      expect(prisma.paymentTransaction.findUnique).not.toHaveBeenCalled();
    });

    it('mengabaikan webhook duplikat (event_id sama sudah pernah diproses)', async () => {
      provider.verifyWebhookSignature.mockReturnValue(true);
      provider.normalizeWebhookPayload.mockReturnValue({
        orderId: 'TLPREF1',
        providerTransactionId: 'midtrans_tx_1',
        normalizedStatus: 'PAID',
        rawStatus: 'settlement',
        grossAmount: 39000,
        eventId: 'midtrans_tx_1:settlement',
      });
      prisma.processed_Webhook_Event.create.mockRejectedValue(
        new Error('Unique constraint failed'),
      );

      const result = await service.handleWebhook({ order_id: 'TLPREF1' });
      expect(result.status).toBe('duplicate_ignored');
      expect(prisma.paymentTransaction.findUnique).not.toHaveBeenCalled();
    });
  });

  describe('completePaidTransaction (via handleWebhook) - Bagian 20, 21, 56, 57, 58', () => {
    const paidEvent = {
      orderId: 'TLPREF1',
      providerTransactionId: 'midtrans_tx_1',
      normalizedStatus: 'PAID' as const,
      rawStatus: 'settlement',
      grossAmount: 39000,
      eventId: 'midtrans_tx_1:settlement',
    };

    beforeEach(() => {
      provider.verifyWebhookSignature.mockReturnValue(true);
      provider.normalizeWebhookPayload.mockReturnValue(paidEvent);
      prisma.processed_Webhook_Event.create.mockResolvedValue({});
    });

    it('mengaktifkan subscription HANYA jika amount provider cocok dengan amount internal (menolak price/amount mismatch)', async () => {
      prisma.paymentTransaction.findUnique.mockResolvedValue(makeTx({ amount: 39000 }));
      provider.normalizeWebhookPayload.mockReturnValue({ ...paidEvent, grossAmount: 1 });
      prisma.paymentTransaction.findUniqueOrThrow.mockResolvedValue(makeTx({ amount: 39000 }));

      await service.handleWebhook({});

      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
      expect(prisma.paymentTransaction.updateMany).not.toHaveBeenCalled();
    });

    it('mengaktifkan subscription via compare-and-set (updateMany) saat status masih PENDING/CREATED', async () => {
      prisma.paymentTransaction.findUnique.mockResolvedValue(makeTx());
      prisma.paymentTransaction.updateMany.mockResolvedValue({ count: 1 });
      prisma.subscription.upsert.mockResolvedValue({ id: 'sub_1' });
      prisma.paymentTransaction.update.mockResolvedValue(makeTx({ status: 'PAID' }));
      prisma.paymentTransaction.findUniqueOrThrow.mockResolvedValue(makeTx({ status: 'PAID' }));

      await service.handleWebhook({});

      expect(prisma.paymentTransaction.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            id: 'tx_1',
            status: { in: [PaymentTransactionStatus.CREATED, PaymentTransactionStatus.PENDING] },
          }),
          data: expect.objectContaining({ status: PaymentTransactionStatus.PAID }),
        }),
      );
      expect(prisma.subscription.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId },
          create: expect.objectContaining({ planCode: PlanCode.PRO, status: 'ACTIVE' }),
        }),
      );
    });

    it('TIDAK mengaktifkan subscription kedua kalinya saat webhook PAID diterima berulang (compare-and-set kalah => no-op)', async () => {
      prisma.paymentTransaction.findUnique.mockResolvedValue(makeTx({ status: 'PAID' }));
      prisma.paymentTransaction.updateMany.mockResolvedValue({ count: 0 });
      prisma.paymentTransaction.findUniqueOrThrow.mockResolvedValue(makeTx({ status: 'PAID' }));

      await service.handleWebhook({});

      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    });
  });
});
