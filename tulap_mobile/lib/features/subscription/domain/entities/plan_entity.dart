import 'billing_cycle.dart';
import 'plan_code.dart';

/// PlanEntity
/// ----------------------------------------------------------------------
/// Satu paket Tulap (folder). SATU-SATUNYA bentuk data paket yang boleh
/// dibaca UI - lihat `PlanConfig` (data layer) untuk sumber kebenaran
/// tunggal nilainya. Jangan hard-code harga/benefit di widget manapun,
/// selalu baca dari instance ini.
///
/// `activityLimit` adalah informasi paling prominent (Bagian 21/23
/// dokumen redesign) - kuota dihitung dari JUMLAH KEGIATAN yang dibuat
/// dalam periode berjalan, bukan foto/nota/LPJ/bukti individual (Bagian
/// 22).
/// ----------------------------------------------------------------------
class PlanEntity {
  final PlanCode code;
  final String displayName;
  final String tabLabel;
  final String? badgeLabel;
  final String description;
  final int activityLimit;
  final int monthlyPrice;
  final int annualPrice;
  final List<String> benefits;
  final String ctaLabel;

  const PlanEntity({
    required this.code,
    required this.displayName,
    required this.tabLabel,
    this.badgeLabel,
    required this.description,
    required this.activityLimit,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.benefits,
    required this.ctaLabel,
  });

  bool get isFree => monthlyPrice == 0 && annualPrice == 0;

  int priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.monthly ? monthlyPrice : annualPrice;

  /// Estimasi setara per-bulan untuk harga tahunan (Bagian 26) - dihitung
  /// dari data, TIDAK PERNAH string hasil hitung manual/hard-code.
  int get annualEquivalentMonthly => (annualPrice / 12).round();

  /// Hemat per tahun dibanding membayar bulanan 12x (Bagian 26) - selalu
  /// dihitung dari `monthlyPrice`/`annualPrice`, bukan nilai tetap.
  int get annualSavingAmount {
    final payAsMonthly = monthlyPrice * 12;
    final saving = payAsMonthly - annualPrice;
    return saving > 0 ? saving : 0;
  }
}
