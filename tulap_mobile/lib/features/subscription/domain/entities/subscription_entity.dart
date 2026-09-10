import 'billing_cycle.dart';
import 'plan_code.dart';
import 'subscription_owner_type.dart';
import 'subscription_status.dart';

/// SubscriptionEntity
/// ----------------------------------------------------------------------
/// Langganan aktif milik satu owner. Arsitektur ini SENGAJA tidak
/// memakai `user.isPremium = true` (Bagian 34 dokumen redesign) - status,
/// periode, dan owner dimodelkan eksplisit agar future-ready terhadap
/// integrasi payment gateway maupun paket instansi tanpa migrasi ulang.
/// ----------------------------------------------------------------------
class SubscriptionEntity {
  final String id;
  final SubscriptionOwnerType ownerType;
  final String ownerId;
  final PlanCode planCode;
  final BillingCycle billingCycle;
  final SubscriptionStatus status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;

  const SubscriptionEntity({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.planCode,
    required this.billingCycle,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
  });

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;

  SubscriptionEntity copyWith({
    PlanCode? planCode,
    BillingCycle? billingCycle,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
  }) {
    return SubscriptionEntity(
      id: id,
      ownerType: ownerType,
      ownerId: ownerId,
      planCode: planCode ?? this.planCode,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    );
  }
}
