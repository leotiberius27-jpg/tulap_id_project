/// PlanCode
/// ----------------------------------------------------------------------
/// Identitas kanonik tiap paket Tulap. Urutan enum SENGAJA menaik sesuai
/// urutan tampil di carousel (Gratis -> Basic -> Pro -> Pro+) sehingga
/// `PlanCode.values.indexOf(code)` bisa langsung dipakai sebagai index
/// carousel tanpa tabel pemetaan terpisah.
/// ----------------------------------------------------------------------
enum PlanCode {
  gratis,
  basic,
  pro,
  proPlus;

  /// Nilai enum PlanCode persis seperti backend (prisma/schema.prisma) -
  /// dipakai PaymentsRemoteDataSource/SubscriptionRemoteDataSource.
  /// JANGAN diubah tanpa mengubah backend plan-catalog.ts juga.
  String get apiValue => switch (this) {
    PlanCode.gratis => 'GRATIS',
    PlanCode.basic => 'BASIC',
    PlanCode.pro => 'PRO',
    PlanCode.proPlus => 'PRO_PLUS',
  };

  static PlanCode fromApiValue(String value) => switch (value) {
    'BASIC' => PlanCode.basic,
    'PRO' => PlanCode.pro,
    'PRO_PLUS' => PlanCode.proPlus,
    _ => PlanCode.gratis,
  };
}
