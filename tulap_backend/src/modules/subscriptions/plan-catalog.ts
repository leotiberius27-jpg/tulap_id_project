import { BillingCycle, PlanCode } from '@prisma/client';

/// PlanCatalog
/// ----------------------------------------------------------------------
/// SATU-SATUNYA sumber kebenaran harga & kuota paket Tulap DI SISI
/// SERVER (Bagian 3 & 8 instruksi payment). Checkout, webhook, dan
/// entitlement SELALU membaca harga dari sini - TIDAK PERNAH dari field
/// `amount` yang dikirim client.
///
/// Mobile `PlanConfig` (tulap_mobile/lib/features/subscription/data/
/// plan_config.dart) adalah salinan tampilan yang HARUS identik dengan
/// tabel ini (dua bahasa berbeda tidak bisa impor satu file yang sama).
/// Jika mengubah harga/kuota di sini, mobile PlanConfig WAJIB diubah
/// mengikuti - keduanya diverifikasi tetap sinkron lewat
/// plan-catalog.spec.ts.
/// ----------------------------------------------------------------------

export interface PlanDefinition {
  code: PlanCode;
  displayName: string;
  activityLimit: number;
  monthlyPrice: number;
  annualPrice: number;
}

export const PLAN_CATALOG: Record<PlanCode, PlanDefinition> = {
  GRATIS: {
    code: PlanCode.GRATIS,
    displayName: 'Gratis',
    activityLimit: 3,
    monthlyPrice: 0,
    annualPrice: 0,
  },
  BASIC: {
    code: PlanCode.BASIC,
    displayName: 'Basic',
    activityLimit: 10,
    monthlyPrice: 19000,
    annualPrice: 190000,
  },
  PRO: {
    code: PlanCode.PRO,
    displayName: 'Tulap Pro',
    activityLimit: 30,
    monthlyPrice: 39000,
    annualPrice: 390000,
  },
  PRO_PLUS: {
    code: PlanCode.PRO_PLUS,
    displayName: 'Tulap Pro+',
    activityLimit: 100,
    monthlyPrice: 69000,
    annualPrice: 690000,
  },
};

export function getPlanDefinition(planCode: PlanCode): PlanDefinition {
  return PLAN_CATALOG[planCode];
}

/// Harga otoritatif SERVER untuk kombinasi paket + siklus penagihan.
/// Dipanggil oleh PaymentsService.checkout() - lihat Bagian 8 instruksi
/// payment ("Server Menentukan Harga").
export function getPlanPrice(planCode: PlanCode, billingCycle: BillingCycle): number {
  const plan = getPlanDefinition(planCode);
  return billingCycle === BillingCycle.ANNUAL ? plan.annualPrice : plan.monthlyPrice;
}

export function getPlanActivityLimit(planCode: PlanCode): number {
  return getPlanDefinition(planCode).activityLimit;
}

/// Menghitung akhir periode billing dari titik mulai - kalender bulan
/// untuk MONTHLY (mengikuti tanggal, bukan 30 hari tetap), tahun kalender
/// untuk ANNUAL. Dipakai baik oleh aktivasi subscription berbayar maupun
/// default GRATIS.
export function calculatePeriodEnd(start: Date, billingCycle: BillingCycle): Date {
  const end = new Date(start);
  if (billingCycle === BillingCycle.ANNUAL) {
    end.setFullYear(end.getFullYear() + 1);
  } else {
    end.setMonth(end.getMonth() + 1);
  }
  return end;
}
