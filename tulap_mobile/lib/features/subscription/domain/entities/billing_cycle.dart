/// BillingCycle
/// ----------------------------------------------------------------------
/// Siklus penagihan paket Tulap - memengaruhi harga mana (`monthlyPrice`
/// atau `annualPrice`) yang ditampilkan dari [PlanEntity], TIDAK mengubah
/// paket yang sedang dipilih di carousel (lihat SubscriptionController).
/// ----------------------------------------------------------------------
enum BillingCycle {
  monthly,
  annual;

  String get label => switch (this) {
    BillingCycle.monthly => 'Bulanan',
    BillingCycle.annual => 'Tahunan',
  };

  String get priceSuffix => switch (this) {
    BillingCycle.monthly => '/bulan',
    BillingCycle.annual => '/tahun',
  };

  String get apiValue => switch (this) {
    BillingCycle.monthly => 'MONTHLY',
    BillingCycle.annual => 'ANNUAL',
  };

  static BillingCycle fromApiValue(String value) =>
      value == 'ANNUAL' ? BillingCycle.annual : BillingCycle.monthly;
}
