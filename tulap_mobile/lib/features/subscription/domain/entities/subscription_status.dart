/// SubscriptionStatus
/// ----------------------------------------------------------------------
/// Status siklus hidup langganan. Hanya subset yang benar-benar dipakai
/// UI sekarang (ACTIVE untuk paket berjalan, EXPIRED untuk paket yang
/// sudah lewat masa berlaku tanpa perpanjangan) - status lain disediakan
/// di domain model agar arsitektur future-ready terhadap integrasi
/// payment gateway sungguhan tanpa perlu migrasi ulang, sesuai prinsip
/// "jangan over-engineer UI" pada dokumen spesifikasi redesign paket.
/// ----------------------------------------------------------------------
enum SubscriptionStatus {
  trial,
  active,
  paymentDue,
  gracePeriod,
  suspended,
  cancelled,
  expired;

  /// Memetakan enum SubscriptionStatus backend (ACTIVE/INACTIVE/EXPIRED/
  /// CANCELLED, prisma/schema.prisma) ke subset yang dipakai UI mobile.
  static SubscriptionStatus fromApiValue(String value) => switch (value) {
    'ACTIVE' => SubscriptionStatus.active,
    'EXPIRED' => SubscriptionStatus.expired,
    'CANCELLED' => SubscriptionStatus.cancelled,
    'INACTIVE' => SubscriptionStatus.suspended,
    _ => SubscriptionStatus.expired,
  };
}
