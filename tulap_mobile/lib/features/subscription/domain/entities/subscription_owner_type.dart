/// SubscriptionOwnerType
/// ----------------------------------------------------------------------
/// Sengaja BUKAN `user.isPremium = true`. Langganan dimodelkan sebagai
/// entitas terpisah yang dimiliki (`owner`) oleh sebuah entitas - untuk
/// fase sekarang SELALU [personal] (pegawai membayar sendiri sebagai
/// asisten kerja lapangan pribadi). [organization] disediakan di domain
/// model untuk masa depan (paket instansi/procurement) tapi TIDAK
/// diekspos di UI mana pun sampai benar-benar dibangun.
/// ----------------------------------------------------------------------
enum SubscriptionOwnerType { personal, organization }
