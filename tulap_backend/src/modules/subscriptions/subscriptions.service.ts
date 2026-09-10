import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { BillingCycle, PlanCode, Subscription, SubscriptionStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { calculatePeriodEnd, getPlanActivityLimit, getPlanDefinition } from './plan-catalog';

export interface SubscriptionUsage {
  used: number;
  limit: number;
  periodStart: Date;
  periodEnd: Date;
}

/// SubscriptionsService
/// ----------------------------------------------------------------------
/// Sumber kebenaran status langganan & entitlement personal user.
/// `completeCheckoutActivation()` HANYA dipanggil dari
/// PaymentsService.completePaidTransaction() (pipeline atomik satu-
/// satunya jalur webhook/reconciliation mengaktifkan paket - Bagian 20
/// & 21 instruksi payment) - TIDAK PERNAH dipanggil langsung dari
/// controller manapun.
/// ----------------------------------------------------------------------
@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  /// Mengembalikan subscription user, membuat baris GRATIS default jika
  /// user belum pernah memilih paket apa pun (lazy-create, bukan migrasi
  /// data massal - user lama otomatis dapat baris ini saat pertama kali
  /// diakses).
  async getOrCreateSubscription(userId: string): Promise<Subscription> {
    const existing = await this.prisma.subscription.findUnique({ where: { userId } });
    if (existing) return existing;

    const now = new Date();
    const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    return this.prisma.subscription.create({
      data: {
        userId,
        planCode: PlanCode.GRATIS,
        billingCycle: BillingCycle.MONTHLY,
        status: SubscriptionStatus.ACTIVE,
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
      },
    });
  }

  /// Entitlement efektif user saat ini - subscription EXPIRED/CANCELLED/
  /// INACTIVE turun kembali ke kuota GRATIS (bukan diblokir total),
  /// selaras dengan mobile SubscriptionEntity.isActive.
  effectivePlanCode(subscription: Subscription): PlanCode {
    const isActive =
      subscription.status === SubscriptionStatus.ACTIVE &&
      subscription.currentPeriodEnd.getTime() > Date.now();
    return isActive ? subscription.planCode : PlanCode.GRATIS;
  }

  async getUsage(userId: string): Promise<SubscriptionUsage> {
    const subscription = await this.getOrCreateSubscription(userId);
    const planCode = this.effectivePlanCode(subscription);
    const limit = getPlanActivityLimit(planCode);

    const used = await this.prisma.task_SPPD.count({
      where: {
        assigneeId: userId,
        createdAt: {
          gte: subscription.currentPeriodStart,
          lt: subscription.currentPeriodEnd,
        },
      },
    });

    return {
      used,
      limit,
      periodStart: subscription.currentPeriodStart,
      periodEnd: subscription.currentPeriodEnd,
    };
  }

  async getMySubscriptionView(userId: string) {
    const subscription = await this.getOrCreateSubscription(userId);
    const usage = await this.getUsage(userId);
    const effectivePlanCode = this.effectivePlanCode(subscription);

    return {
      subscription: {
        id: subscription.id,
        planCode: subscription.planCode,
        billingCycle: subscription.billingCycle,
        status: subscription.status,
        currentPeriodStart: subscription.currentPeriodStart,
        currentPeriodEnd: subscription.currentPeriodEnd,
      },
      effectivePlanCode,
      usage,
    };
  }

  /// Backend enforcement kuota kegiatan (Bagian 24 instruksi payment -
  /// "frontend boleh menampilkan quota, tapi backend harus tetap
  /// enforce"). Dipanggil TasksService.create() sebelum membuat
  /// Task_SPPD baru untuk assignee bersangkutan.
  async assertActivityQuotaAvailable(userId: string): Promise<void> {
    const usage = await this.getUsage(userId);
    if (usage.used >= usage.limit) {
      throw new ForbiddenException(
        `Kuota kegiatan bulan ini (${usage.limit}) sudah tercapai. Upgrade paket untuk menambah kuota.`,
      );
    }
  }

  /// Memilih paket GRATIS - TIDAK melalui checkout QRIS/VA (Bagian 41).
  /// Menolak downgrade diam-diam dari paket berbayar yang masih aktif
  /// (Bagian 42 - "jangan diam-diam menghitung/putuskan rule yang belum
  /// disetujui") - user harus menunggu masa aktif berakhir.
  async selectFreePlan(userId: string): Promise<Subscription> {
    const subscription = await this.getOrCreateSubscription(userId);
    const effectivePlanCode = this.effectivePlanCode(subscription);

    if (effectivePlanCode !== PlanCode.GRATIS) {
      throw new BadRequestException(
        'Anda masih memiliki paket berbayar yang aktif. Paket Gratis akan tersedia otomatis setelah masa aktif berakhir.',
      );
    }

    const now = new Date();
    const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    const updated = await this.prisma.subscription.update({
      where: { userId },
      data: {
        planCode: PlanCode.GRATIS,
        billingCycle: BillingCycle.MONTHLY,
        status: SubscriptionStatus.ACTIVE,
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
      },
    });

    await this.audit.log({
      actorId: userId,
      action: 'SUBSCRIPTION_ACTIVATED',
      entity: 'Subscription',
      entityId: updated.id,
      metadata: { planCode: PlanCode.GRATIS, source: 'select_free' },
    });

    return updated;
  }

  getPlanDisplayName(planCode: PlanCode): string {
    return getPlanDefinition(planCode).displayName;
  }

  calculatePeriodEnd(start: Date, billingCycle: BillingCycle): Date {
    return calculatePeriodEnd(start, billingCycle);
  }
}
