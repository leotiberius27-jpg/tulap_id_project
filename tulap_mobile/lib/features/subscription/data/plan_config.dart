import '../domain/entities/plan_code.dart';
import '../domain/entities/plan_entity.dart';

/// PlanConfig
/// ----------------------------------------------------------------------
/// Sumber kebenaran TAMPILAN paket Tulap di mobile (Bagian 20 & 36
/// dokumen redesign Halaman Paket). Setiap layar (carousel, comparison
/// sheet, quota guard) WAJIB membaca dari sini lewat PlanRepository -
/// jangan pernah menulis ulang harga/benefit di widget manapun.
///
/// PENTING (Bagian 3 instruksi payment): harga & kuota OTORITATIF ada di
/// backend - tulap_backend/src/modules/subscriptions/plan-catalog.ts.
/// Checkout QRIS/VA SELALU menghitung ulang harga dari sana, TIDAK
/// PERNAH dari nilai di file ini. Nilai di sini HARUS diubah bersamaan
/// (identik persis) setiap kali plan-catalog.ts diubah - dua bahasa
/// berbeda tidak bisa berbagi satu file sumber.
///
/// Harga tahunan bersifat configurable di satu tempat ini saja - lihat
/// Bagian 26 dokumen redesign untuk hipotesis awal harga tahunan.
/// ----------------------------------------------------------------------
class PlanConfig {
  PlanConfig._();

  static const List<PlanEntity> plans = [
    PlanEntity(
      code: PlanCode.gratis,
      displayName: 'Gratis',
      tabLabel: 'GRATIS',
      description: 'Untuk mencoba cara kerja Tulap.',
      activityLimit: 3,
      monthlyPrice: 0,
      annualPrice: 0,
      benefits: [
        'Foto geotag & watermark',
        'Checklist & sinkronisasi dasar',
        'Arsip kegiatan pribadi',
      ],
      ctaLabel: 'Mulai Gratis',
    ),
    PlanEntity(
      code: PlanCode.basic,
      displayName: 'Basic',
      tabLabel: 'BASIC',
      description: 'Untuk Anda yang sesekali bertugas di lapangan.',
      activityLimit: 10,
      monthlyPrice: 19000,
      annualPrice: 190000,
      benefits: [
        'Foto geotag & watermark',
        'Scan nota otomatis',
        'Offline & sinkronisasi',
        'Pengeluaran & arsip',
      ],
      ctaLabel: 'Pilih Basic',
    ),
    PlanEntity(
      code: PlanCode.pro,
      displayName: 'Tulap Pro',
      tabLabel: 'PRO',
      badgeLabel: 'PALING POPULER',
      description: 'Untuk Anda yang rutin bertugas di lapangan.',
      activityLimit: 30,
      monthlyPrice: 39000,
      annualPrice: 390000,
      benefits: [
        'Foto geotag & watermark',
        'Scan nota otomatis',
        'Offline & sinkronisasi',
        'Tula AI',
        'Pengeluaran & arsip',
        'LPJ PDF & Word',
      ],
      ctaLabel: 'Pilih Tulap Pro',
    ),
    PlanEntity(
      code: PlanCode.proPlus,
      displayName: 'Tulap Pro+',
      tabLabel: 'PRO+',
      description: 'Untuk Anda dengan aktivitas lapangan yang tinggi.',
      activityLimit: 100,
      monthlyPrice: 69000,
      annualPrice: 690000,
      benefits: [
        'Foto geotag & watermark',
        'Scan nota otomatis',
        'Offline & sinkronisasi',
        'Tula AI prioritas',
        'Pengeluaran & arsip',
        'LPJ PDF & Word',
      ],
      ctaLabel: 'Pilih Pro+',
    ),
  ];

  static PlanEntity byCode(PlanCode code) =>
      plans.firstWhere((plan) => plan.code == code, orElse: () => plans.first);
}
