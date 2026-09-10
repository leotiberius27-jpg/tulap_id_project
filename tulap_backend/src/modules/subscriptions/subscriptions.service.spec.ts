import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PlanCode, SubscriptionStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { SubscriptionsService } from './subscriptions.service';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;
  let prisma: any;

  const userId = 'user_1';

  beforeEach(async () => {
    prisma = {
      subscription: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
      task_SPPD: { count: jest.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionsService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuditService, useValue: { log: jest.fn() } },
      ],
    }).compile();

    service = module.get<SubscriptionsService>(SubscriptionsService);
  });

  it('Bagian 24: menolak pembuatan kegiatan baru jika kuota bulan berjalan sudah tercapai', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      id: 'sub_1',
      userId,
      planCode: PlanCode.BASIC,
      status: SubscriptionStatus.ACTIVE,
      currentPeriodStart: new Date('2026-09-01'),
      currentPeriodEnd: new Date('2026-10-01'),
    });
    prisma.task_SPPD.count.mockResolvedValue(10); // BASIC limit = 10

    await expect(service.assertActivityQuotaAvailable(userId)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('mengizinkan pembuatan kegiatan jika masih di bawah kuota', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      id: 'sub_1',
      userId,
      planCode: PlanCode.PRO,
      status: SubscriptionStatus.ACTIVE,
      currentPeriodStart: new Date('2026-09-01'),
      currentPeriodEnd: new Date('2026-10-01'),
    });
    prisma.task_SPPD.count.mockResolvedValue(29); // PRO limit = 30

    await expect(service.assertActivityQuotaAvailable(userId)).resolves.toBeUndefined();
  });

  it('subscription EXPIRED turun kembali ke kuota GRATIS (3), bukan diblokir total', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      id: 'sub_1',
      userId,
      planCode: PlanCode.PRO,
      status: SubscriptionStatus.ACTIVE,
      currentPeriodStart: new Date('2020-01-01'),
      currentPeriodEnd: new Date('2020-02-01'), // sudah lewat
    });
    prisma.task_SPPD.count.mockResolvedValue(3); // GRATIS limit = 3

    await expect(service.assertActivityQuotaAvailable(userId)).rejects.toThrow(
      ForbiddenException,
    );
    // Memverifikasi limit yang dipakai memang GRATIS(3), bukan PRO(30):
    // count=3 sudah menolak, artinya effective plan bukan PRO.
  });

  it('Bagian 41: menolak downgrade diam-diam ke Gratis saat paket berbayar masih aktif', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      id: 'sub_1',
      userId,
      planCode: PlanCode.PRO,
      status: SubscriptionStatus.ACTIVE,
      currentPeriodStart: new Date(),
      currentPeriodEnd: new Date(Date.now() + 30 * 24 * 3600 * 1000),
    });

    await expect(service.selectFreePlan(userId)).rejects.toThrow(BadRequestException);
    expect(prisma.subscription.update).not.toHaveBeenCalled();
  });
});
