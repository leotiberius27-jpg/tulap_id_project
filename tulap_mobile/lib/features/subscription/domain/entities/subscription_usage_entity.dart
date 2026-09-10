/// SubscriptionUsageEntity
/// ----------------------------------------------------------------------
/// Pemakaian kuota kegiatan pada periode berjalan. `used` dihitung dari
/// JUMLAH KEGIATAN yang benar-benar dibuat (`createdAt` di periode
/// berjalan) - lihat SubscriptionRepositoryImpl. Tidak pernah dihitung
/// dari foto/nota/LPJ/bukti individual (Bagian 22 dokumen redesign).
/// ----------------------------------------------------------------------
class SubscriptionUsageEntity {
  final int used;
  final int limit;
  final DateTime periodEnd;

  const SubscriptionUsageEntity({
    required this.used,
    required this.limit,
    required this.periodEnd,
  });

  int get remaining => (limit - used).clamp(0, limit);

  bool get isAtLimit => used >= limit;

  /// Ambang "hampir habis" (Bagian 29) - dianggap dekat limit saat sisa
  /// kuota <= 20% dari limit ATAU sisa <= 3 kegiatan, mana yang lebih
  /// longgar secara proporsional untuk paket kecil maupun besar.
  bool get isNearLimit {
    if (isAtLimit) return false;
    final threshold = (limit * 0.2).ceil().clamp(1, limit);
    return remaining <= threshold || remaining <= 3;
  }

  double get progress => limit == 0 ? 0 : (used / limit).clamp(0.0, 1.0);
}
