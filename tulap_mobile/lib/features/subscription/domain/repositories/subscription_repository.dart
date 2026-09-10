import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plan_code.dart';
import '../entities/subscription_entity.dart';
import '../entities/subscription_usage_entity.dart';

/// SubscriptionRepository (interface/kontrak)
/// ----------------------------------------------------------------------
abstract class SubscriptionRepository {
  /// Langganan personal milik user yang sedang login. `null` berarti
  /// user belum pernah memilih paket - UI memperlakukan ini setara
  /// paket GRATIS tanpa entri langganan eksplisit.
  Future<Either<Failure, SubscriptionEntity?>> getCurrentSubscription();

  /// Pemakaian kuota kegiatan pada periode berjalan, dihitung dari
  /// kegiatan sungguhan yang sudah dibuat user (lihat GetActiveTasks) -
  /// TIDAK PERNAH nilai rekaan.
  Future<Either<Failure, SubscriptionUsageEntity>> getUsage(PlanCode planCode);

  /// HANYA untuk paket GRATIS (Bagian 41 instruksi payment - paket
  /// berbayar WAJIB lewat checkout QRIS/VA, lihat PaymentRepository/
  /// CheckoutController). Backend menolak jika user masih punya paket
  /// berbayar yang aktif (mencegah downgrade diam-diam, Bagian 42).
  Future<Either<Failure, SubscriptionEntity>> selectFreePlan();
}
